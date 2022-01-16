# frozen_string_literal: true

require "spec_helper"

module Decidim
  module EnhancedTextwork
    module Admin
      describe ImportParagraphs do
        describe "call" do
          let!(:organization) { create(:organization) }
          let!(:paragraph) { create(:paragraph, :accepted, component: paragraph_component) }
          let!(:paragraph_component) do
            create(
              :paragraph_component,
              organization: organization
            )
          end
          let!(:current_component) do
            create(
              :paragraph_component,
              participatory_space: paragraph_component.participatory_space,
              organization: organization
            )
          end

          let(:form) do
            instance_double(
              ParagraphsImportForm,
              origin_component: paragraph_component,
              current_component: current_component,
              current_organization: organization,
              keep_authors: keep_authors,
              keep_answers: keep_answers,
              states: states,
              scopes: scopes,
              scope_ids: scope_ids,
              current_user: create(:user, organization: organization),
              valid?: valid
            )
          end
          let(:keep_authors) { false }
          let(:keep_answers) { false }
          let(:states) { ["accepted"] }
          let(:scopes) { [] }
          let(:scope_ids) { scopes.map(&:id) }
          let(:command) { described_class.new(form) }

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

            it "creates the paragraphs" do
              expect do
                command.call
              end.to change { Paragraph.where(component: current_component).count }.by(1)
            end

            context "when a paragraph was already imported" do
              let(:second_paragraph) { create(:paragraph, :accepted, component: paragraph_component) }

              before do
                command.call
                second_paragraph
              end

              it "doesn't import it again" do
                expect do
                  command.call
                end.to change { Paragraph.where(component: current_component).count }.by(1)

                titles = Paragraph.where(component: current_component).map(&:title)
                expect(titles).to match_array([paragraph.title, second_paragraph.title])
              end
            end

            it "links the paragraphs" do
              command.call

              linked = paragraph.linked_resources(:paragraphs, "copied_from_component")
              new_paragraph = Paragraph.where(component: current_component).last

              expect(linked).to include(new_paragraph)
            end

            it "only imports wanted attributes" do
              command.call

              new_paragraph = Paragraph.where(component: current_component).last
              expect(new_paragraph.title).to eq(paragraph.title)
              expect(new_paragraph.body).to eq(paragraph.body)
              expect(new_paragraph.creator_author).to eq(organization)
              expect(new_paragraph.category).to eq(paragraph.category)

              expect(new_paragraph.state).to be_nil
              expect(new_paragraph.answer).to be_nil
              expect(new_paragraph.answered_at).to be_nil
              expect(new_paragraph.reference).not_to eq(paragraph.reference)
              expect(new_paragraph.comments_count).to eq 0
              expect(new_paragraph.endorsements_count).to eq 0
              expect(new_paragraph.follows_count).to eq 0
              expect(new_paragraph.paragraph_notes_count).to eq 0
              expect(new_paragraph.paragraph_votes_count).to eq 0
            end

            describe "when keep_authors is true" do
              let(:keep_authors) { true }

              it "only keeps the paragraph authors" do
                command.call

                new_paragraph = Paragraph.where(component: current_component).last
                expect(new_paragraph.title).to eq(paragraph.title)
                expect(new_paragraph.body).to eq(paragraph.body)
                expect(new_paragraph.creator_author).to eq(paragraph.creator_author)
              end
            end

            describe "when keep_answers is true" do
              let(:keep_answers) { true }

              it "keeps the paragraph state and answers" do
                command.call

                new_paragraph = Paragraph.where(component: current_component).last
                expect(new_paragraph.answer).to eq(paragraph.answer)
                expect(new_paragraph.answered_at).to be_within(1.second).of(paragraph.answered_at)
                expect(new_paragraph.state).to eq(paragraph.state)
                expect(new_paragraph.state_published_at).to be_within(1.second).of(paragraph.state_published_at)
              end
            end

            describe "paragraph states" do
              let(:states) { %w(not_answered rejected) }

              before do
                create(:paragraph, :rejected, component: paragraph_component)
                create(:paragraph, component: paragraph_component)
              end

              it "only imports paragraphs from the selected states" do
                expect do
                  command.call
                end.to change { Paragraph.where(component: current_component).count }.by(2)

                expect(Paragraph.where(component: current_component).pluck(:title)).not_to include(paragraph.title)
              end
            end

            describe "paragraph scopes" do
              let(:states) { ParagraphsImportForm::VALID_STATES.dup }
              let(:scope) { create(:scope, organization: organization) }
              let(:other_scope) { create(:scope, organization: organization) }

              let(:scopes) { [scope] }
              let(:scope_ids) { [scope.id] }

              let!(:paragraphs) do
                [
                  create(:paragraph, component: paragraph_component, scope: scope),
                  create(:paragraph, component: paragraph_component, scope: other_scope)
                ]
              end

              it "only imports paragraphs from the selected scope" do
                expect do
                  command.call
                end.to change { Paragraph.where(component: current_component).count }.by(1)

                expect(Paragraph.where(component: current_component).pluck(:decidim_scope_id)).to eq([scope.id])
              end

              context "when the global scope is selected" do
                let(:scope) { nil }
                let(:scope_ids) { [nil] }

                it "only imports paragraphs from the global scope" do
                  expect do
                    command.call
                  end.to change { Paragraph.where(component: current_component).count }.by(2)

                  expect(Paragraph.where(component: current_component).pluck(:decidim_scope_id)).to eq([nil, nil])
                end
              end
            end

            describe "when the paragraph has attachments" do
              let!(:attachment) do
                create(:attachment, attached_to: paragraph)
              end

              it "duplicates the attachments" do
                expect do
                  command.call
                end.to change(Attachment, :count).by(1)

                new_paragraph = Paragraph.where(component: current_component).last
                expect(new_paragraph.attachments.count).to eq(1)
              end
            end
          end
        end
      end
    end
  end
end
