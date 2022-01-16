# frozen_string_literal: true

require "spec_helper"

describe Decidim::EnhancedTextwork::Metrics::ParagraphParticipantsMetricMeasure do
  let(:day) { Time.zone.yesterday }
  let(:organization) { create(:organization) }
  let(:not_valid_resource) { create(:dummy_resource) }
  let(:participatory_space) { create(:participatory_process, :with_steps, organization: organization) }

  let(:paragraphs_component) { create(:paragraph_component, :published, participatory_space: participatory_space) }
  let!(:paragraph) { create(:paragraph, :with_endorsements, published_at: day, component: paragraphs_component) }
  let!(:old_paragraph) { create(:paragraph, :with_endorsements, published_at: day - 1.week, component: paragraphs_component) }
  let!(:paragraph_votes) { create_list(:paragraph_vote, 10, created_at: day, paragraph: paragraph) }
  let!(:old_paragraph_votes) { create_list(:paragraph_vote, 5, created_at: day - 1.week, paragraph: old_paragraph) }
  let!(:paragraph_endorsements) do
    5.times.collect do
      create(:endorsement, created_at: day, resource: paragraph, author: build(:user, organization: organization))
    end
  end
  # TOTAL Participants for Paragraphs:
  #  Cumulative: 22 ( 2 paragraph, 15 votes, 5 endorsements )
  #  Quantity: 16 ( 1 paragraph, 10 votes, 5 endorsements )

  context "when executing class" do
    it "fails to create object with an invalid resource" do
      manager = described_class.new(day, not_valid_resource)

      expect(manager).not_to be_valid
    end

    it "calculates" do
      result = described_class.new(day, paragraphs_component).calculate

      expect(result[:cumulative_users].count).to eq(22)
      expect(result[:quantity_users].count).to eq(16)
    end

    it "does not found any result for past days" do
      result = described_class.new(day - 1.month, paragraphs_component).calculate

      expect(result[:cumulative_users].count).to eq(0)
      expect(result[:quantity_users].count).to eq(0)
    end
  end
end
