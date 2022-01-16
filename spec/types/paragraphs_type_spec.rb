# frozen_string_literal: true

require "spec_helper"
require "decidim/api/test/type_context"
require "decidim/core/test"

module Decidim
  module EnhancedTextwork
    describe ParagraphsType, type: :graphql do
      include_context "with a graphql class type"
      let(:model) { create(:paragraph_component) }

      it_behaves_like "a component query type"

      describe "paragraphs" do
        let!(:draft_paragraphs) { create_list(:paragraph, 2, :draft, component: model) }
        let!(:published_paragraphs) { create_list(:paragraph, 2, component: model) }
        let!(:other_paragraphs) { create_list(:paragraph, 2) }

        let(:query) { "{ paragraphs { edges { node { id } } } }" }

        it "returns the published paragraphs" do
          ids = response["paragraphs"]["edges"].map { |edge| edge["node"]["id"] }
          # We expect the default order to be ascending by ID, so the array
          # needs to match exactly the ordered IDs array.
          expect(ids).to eq(published_paragraphs.map(&:id).sort.map(&:to_s))
          expect(ids).not_to include(*draft_paragraphs.map(&:id).map(&:to_s))
          expect(ids).not_to include(*other_paragraphs.map(&:id).map(&:to_s))
        end

        context "when querying paragraphs with categories" do
          let(:category) { create(:category, participatory_space: model.participatory_space) }
          let!(:paragraph_with_category) { create(:paragraph, component: model, category: category) }
          let(:all_paragraphs) { published_paragraphs + [paragraph_with_category] }

          let(:query) { "{ paragraphs { edges { node { id, category { id } } } } }" }

          it "return paragraphs with and without categories" do
            ids = response["paragraphs"]["edges"].map { |edge| edge["node"]["id"] }
            expect(ids.count).to eq(3)
            expect(ids).to eq(all_paragraphs.map(&:id).sort.map(&:to_s))
          end
        end
      end

      describe "paragraph" do
        let(:query) { "query Paragraph($id: ID!){ paragraph(id: $id) { id } }" }
        let(:variables) { { id: paragraph.id.to_s } }

        context "when the paragraph belongs to the component" do
          let!(:paragraph) { create(:paragraph, component: model) }

          it "finds the paragraph" do
            expect(response["paragraph"]["id"]).to eq(paragraph.id.to_s)
          end
        end

        context "when the paragraph doesn't belong to the component" do
          let!(:paragraph) { create(:paragraph, component: create(:paragraph_component)) }

          it "returns null" do
            expect(response["paragraph"]).to be_nil
          end
        end

        context "when the paragraph is not published" do
          let!(:paragraph) { create(:paragraph, :draft, component: model) }

          it "returns null" do
            expect(response["paragraph"]).to be_nil
          end
        end
      end
    end
  end
end
