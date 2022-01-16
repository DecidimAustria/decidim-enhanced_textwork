# frozen_string_literal: true

require "spec_helper"

module Decidim
  module EnhancedTextwork
    module Admin
      describe MergeParagraphs do
        describe "call" do
          let!(:paragraphs) { create_list(:paragraph, 3, component: current_component) }
          let!(:current_component) { create(:paragraph_component) }
          let!(:target_component) { create(:paragraph_component, participatory_space: current_component.participatory_space) }
          let(:form) do
            instance_double(
              ParagraphsMergeForm,
              current_component: current_component,
              current_organization: current_component.organization,
              target_component: target_component,
              paragraphs: paragraphs,
              valid?: valid,
              same_component?: same_component,
              current_user: create(:user, :admin, organization: current_component.organization)
            )
          end
          let(:command) { described_class.new(form) }
          let(:same_component) { false }

          describe "when the form is not valid" do
            let(:valid) { false }

            it "broadcasts invalid" do
              expect { command.call }.to broadcast(:invalid)
            end

            it "doesn't create the paragraph" do
              expect do
                command.call
              end.to change(Paragraph, :count).by(0)
            end
          end

          describe "when the form is valid" do
            let(:valid) { true }

            it "broadcasts ok" do
              expect { command.call }.to broadcast(:ok)
            end

            it "creates a paragraph in the new component" do
              expect do
                command.call
              end.to change { Paragraph.where(component: target_component).count }.by(1)
            end

            it "links the paragraphs" do
              command.call
              paragraph = Paragraph.where(component: target_component).last

              linked = paragraph.linked_resources(:paragraphs, "copied_from_component")

              expect(linked).to match_array(paragraphs)
            end

            it "only merges wanted attributes" do
              command.call
              new_paragraph = Paragraph.where(component: target_component).last
              paragraph = paragraphs.first

              expect(new_paragraph.title).to eq(paragraph.title)
              expect(new_paragraph.body).to eq(paragraph.body)
              expect(new_paragraph.creator_author).to eq(current_component.organization)
              expect(new_paragraph.category).to eq(paragraph.category)

              expect(new_paragraph.state).to be_nil
              expect(new_paragraph.answer).to be_nil
              expect(new_paragraph.answered_at).to be_nil
              expect(new_paragraph.reference).not_to eq(paragraph.reference)
            end

            context "when merging from the same component" do
              let(:same_component) { true }
              let(:target_component) { current_component }

              it "deletes the original paragraphs" do
                command.call
                paragraph_ids = paragraphs.map(&:id)

                expect(Decidim::EnhancedTextwork::Paragraph.where(id: paragraph_ids)).to be_empty
              end

              it "links the merged paragraph to the links the other paragraphs had" do
                other_component = create(:paragraph_component, participatory_space: current_component.participatory_space)
                other_paragraphs = create_list(:paragraph, 3, component: other_component)

                paragraphs.each_with_index do |paragraph, index|
                  paragraph.link_resources(other_paragraphs[index], "copied_from_component")
                end

                command.call

                paragraph = Paragraph.where(component: target_component).last
                linked = paragraph.linked_resources(:paragraphs, "copied_from_component")
                expect(linked).to match_array(other_paragraphs)
              end
            end
          end
        end
      end
    end
  end
end
