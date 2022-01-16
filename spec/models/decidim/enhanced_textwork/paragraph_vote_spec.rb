# frozen_string_literal: true

require "spec_helper"

module Decidim
  module EnhancedTextwork
    describe ParagraphVote do
      subject { paragraph_vote }

      let!(:organization) { create(:organization) }
      let!(:component) { create(:component, organization: organization, manifest_name: "paragraphs") }
      let!(:participatory_process) { create(:participatory_process, organization: organization) }
      let!(:author) { create(:user, organization: organization) }
      let!(:paragraph) { create(:paragraph, component: component, users: [author]) }
      let!(:paragraph_vote) { build(:paragraph_vote, paragraph: paragraph, author: author) }

      it "is valid" do
        expect(paragraph_vote).to be_valid
      end

      it "has an associated author" do
        expect(paragraph_vote.author).to be_a(Decidim::User)
      end

      it "has an associated paragraph" do
        expect(paragraph_vote.paragraph).to be_a(Decidim::EnhancedTextwork::Paragraph)
      end

      it "validates uniqueness for author and paragraph combination" do
        paragraph_vote.save!
        expect do
          create(:paragraph_vote, paragraph: paragraph, author: author)
        end.to raise_error(ActiveRecord::RecordInvalid)
      end

      context "when no author" do
        before do
          paragraph_vote.author = nil
        end

        it { is_expected.to be_invalid }
      end

      context "when no paragraph" do
        before do
          paragraph_vote.paragraph = nil
        end

        it { is_expected.to be_invalid }
      end

      context "when paragraph and author have different organization" do
        let(:other_author) { create(:user) }
        let(:other_paragraph) { create(:paragraph) }

        it "is invalid" do
          paragraph_vote = build(:paragraph_vote, paragraph: other_paragraph, author: other_author)
          expect(paragraph_vote).to be_invalid
        end
      end

      context "when paragraph is rejected" do
        let!(:paragraph) { create(:paragraph, :rejected, component: component, users: [author]) }

        it { is_expected.to be_invalid }
      end
    end
  end
end
