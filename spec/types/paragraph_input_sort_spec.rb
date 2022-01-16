# frozen_string_literal: true

require "spec_helper"
require "decidim/api/test/type_context"
require "decidim/core/test"
require "decidim/core/test/shared_examples/input_sort_examples"

module Decidim
  module EnhancedTextwork
    describe ParagraphInputSort, type: :graphql do
      include_context "with a graphql class type"

      let(:type_class) { Decidim::EnhancedTextwork::ParagraphsType }

      let(:model) { create(:paragraph_component) }
      let!(:models) { create_list(:paragraph, 3, :published, component: model) }

      context "when sorting by paragraphs id" do
        include_examples "connection has input sort", "paragraphs", "id"
      end

      context "when sorting by published_at" do
        include_examples "connection has input sort", "paragraphs", "publishedAt"
      end

      context "when sorting by endorsement_count" do
        let!(:most_endorsed) { create(:paragraph, :published, :with_endorsements, component: model) }

        include_examples "connection has endorsement_count sort", "paragraphs"
      end

      context "when sorting by vote_count" do
        let!(:votes) { create_list(:paragraph_vote, 3, paragraph: models.last) }

        describe "ASC" do
          let(:query) { %[{ paragraphs(order: {voteCount: "ASC"}) { edges { node { id } } } }] }

          it "returns the most voted last" do
            expect(response["paragraphs"]["edges"].count).to eq(3)
            expect(response["paragraphs"]["edges"].last["node"]["id"]).to eq(models.last.id.to_s)
          end
        end

        describe "DESC" do
          let(:query) { %[{ paragraphs(order: {voteCount: "DESC"}) { edges { node { id } } } }] }

          it "returns the most voted first" do
            expect(response["paragraphs"]["edges"].count).to eq(3)
            expect(response["paragraphs"]["edges"].first["node"]["id"]).to eq(models.last.id.to_s)
          end
        end
      end
    end
  end
end
