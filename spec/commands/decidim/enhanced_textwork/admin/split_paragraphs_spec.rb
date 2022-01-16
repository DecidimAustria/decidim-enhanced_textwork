# frozen_string_literal: true

require "spec_helper"

module Decidim
  module EnhancedTextwork
    module Admin
      describe SplitParagraphs do
        describe "call" do
          let!(:paragraphs) { Array(create(:paragraph, component: current_component)) }
          let!(:current_component) { create(:paragraph_component) }
          let!(:target_component) { create(:paragraph_component, participatory_space: current_component.participatory_space) }
          let(:form) do
            instance_double(
              ParagraphsSplitForm,
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

            it "creates two paragraphs for each original in the new component" do
              expect do
                command.call
              end.to change { Paragraph.where(component: target_component).count }.by(2)
            end

            it "links the paragraphs" do
              command.call
              new_paragraphs = Paragraph.where(component: target_component)

              linked = paragraphs.first.linked_resources(:paragraphs, "copied_from_component")

              expect(linked).to match_array(new_paragraphs)
            end

            it "only copies wanted attributes" do
              command.call
              paragraph = paragraphs.first
              new_paragraph = Paragraph.where(component: target_component).last

              expect(new_paragraph.title).to eq(paragraph.title)
              expect(new_paragraph.body).to eq(paragraph.body)
              expect(new_paragraph.creator_author).to eq(current_component.organization)
              expect(new_paragraph.category).to eq(paragraph.category)

              expect(new_paragraph.state).to be_nil
              expect(new_paragraph.answer).to be_nil
              expect(new_paragraph.answered_at).to be_nil
              expect(new_paragraph.reference).not_to eq(paragraph.reference)
            end

            context "when spliting to the same component" do
              let(:same_component) { true }
              let!(:target_component) { current_component }
              let!(:paragraphs) { create_list(:paragraph, 2, component: current_component) }

              it "only creates one copy for each paragraph" do
                expect do
                  command.call
                end.to change { Paragraph.where(component: current_component).count }.by(2)
              end

              context "when the original paragraph has links to other paragraphs" do
                let(:previous_component) { create(:paragraph_component, participatory_space: current_component.participatory_space) }
                let(:previous_paragraphs) { create(:paragraph, component: previous_component) }

                before do
                  paragraphs.each do |paragraph|
                    paragraph.link_resources(previous_paragraphs, "copied_from_component")
                  end
                end

                it "links the copy to the same links the paragraph has" do
                  new_paragraphs = Paragraph.where(component: target_component).last(2)

                  new_paragraphs.each do |paragraph|
                    linked = paragraph.linked_resources(:paragraphs, "copied_from_component")
                    expect(linked).to eq([previous_paragraphs])
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
