# frozen_string_literal: true

require "spec_helper"

module Decidim
  module EnhancedTextwork
    module Admin
      describe UpdateParagraphCategory do
        describe "call" do
          let(:organization) { create(:organization) }

          let!(:paragraph) { create :paragraph }
          let!(:paragraphs) { create_list(:paragraph, 3, component: paragraph.component) }
          let!(:category_one) { create :category, participatory_space: paragraph.component.participatory_space }
          let!(:category) { create :category, participatory_space: paragraph.component.participatory_space }

          context "with no category" do
            it "broadcasts invalid_category" do
              expect { described_class.call(nil, paragraph.id) }.to broadcast(:invalid_category)
            end
          end

          context "with no paragraphs" do
            it "broadcasts invalid_paragraph_ids" do
              expect { described_class.call(category.id, nil) }.to broadcast(:invalid_paragraph_ids)
            end
          end

          describe "with a category and paragraphs" do
            context "when the category is the same as the paragraph's category" do
              before do
                paragraph.update!(category: category)
              end

              it "doesn't update the paragraph" do
                expect(paragraph).not_to receive(:update!)
                described_class.call(paragraph.category.id, paragraph.id)
              end
            end

            context "when the category is diferent from the paragraph's category" do
              before do
                paragraphs.each { |p| p.update!(category: category_one) }
              end

              it "broadcasts update_paragraphs_category" do
                expect { described_class.call(category.id, paragraphs.pluck(:id)) }.to broadcast(:update_paragraphs_category)
              end

              it "updates the paragraph" do
                described_class.call(category.id, paragraph.id)

                expect(paragraph.reload.category).to eq(category)
              end
            end
          end
        end
      end
    end
  end
end
