# frozen_string_literal: true

require "spec_helper"

module Decidim
  module EnhancedTextwork
    module Admin
      describe ParagraphRankingsHelper do
        let(:component) { create(:paragraph_component) }

        let!(:paragraph1) { create :paragraph, component: component, paragraph_votes_count: 4 }
        let!(:paragraph2) { create :paragraph, component: component, paragraph_votes_count: 2 }
        let!(:paragraph3) { create :paragraph, component: component, paragraph_votes_count: 2 }
        let!(:paragraph4) { create :paragraph, component: component, paragraph_votes_count: 1 }

        let!(:external_paragraph) { create :paragraph, paragraph_votes_count: 8 }

        describe "ranking_for" do
          it "returns the ranking considering only sibling paragraphs" do
            result = helper.ranking_for(paragraph1, paragraph_votes_count: :desc)

            expect(result).to eq(ranking: 1, total: 4)
          end

          it "breaks ties by ordering by ID" do
            result = helper.ranking_for(paragraph3, paragraph_votes_count: :desc)

            expect(result).to eq(ranking: 3, total: 4)
          end
        end
      end
    end
  end
end
