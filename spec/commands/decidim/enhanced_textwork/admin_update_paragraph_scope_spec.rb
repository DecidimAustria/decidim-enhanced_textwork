# frozen_string_literal: true

require "spec_helper"

module Decidim
  module EnhancedTextwork
    module Admin
      describe UpdateParagraphScope do
        describe "call" do
          let!(:paragraph) { create :paragraph }
          let!(:paragraphs) { create_list(:paragraph, 3, component: paragraph.component) }
          let!(:scope_one) { create :scope, organization: paragraph.organization }
          let!(:scope) { create :scope, organization: paragraph.organization }

          context "with no scope" do
            it "broadcasts invalid_scope" do
              expect { described_class.call(nil, paragraph.id) }.to broadcast(:invalid_scope)
            end
          end

          context "with no paragraphs" do
            it "broadcasts invalid_paragraph_ids" do
              expect { described_class.call(scope.id, nil) }.to broadcast(:invalid_paragraph_ids)
            end
          end

          describe "with a scope and paragraphs" do
            context "when the scope is the same as the paragraph's scope" do
              before do
                paragraph.update!(scope: scope)
              end

              it "doesn't update the paragraph" do
                expect(paragraph).not_to receive(:update!)
                described_class.call(paragraph.scope.id, paragraph.id)
              end
            end

            context "when the scope is diferent from the paragraph's scope" do
              before do
                paragraphs.each { |p| p.update!(scope: scope_one) }
              end

              it "broadcasts update_paragraphs_scope" do
                expect { described_class.call(scope.id, paragraphs.pluck(:id)) }.to broadcast(:update_paragraphs_scope)
              end

              it "updates the paragraph" do
                described_class.call(scope.id, paragraph.id)

                expect(paragraph.reload.scope).to eq(scope)
              end
            end
          end
        end
      end
    end
  end
end
