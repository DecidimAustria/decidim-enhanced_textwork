# frozen_string_literal: true

require "spec_helper"

module Decidim
  module EnhancedTextwork
    describe ParagraphNote do
      subject { paragraph_note }

      let!(:organization) { create(:organization) }
      let!(:component) { create(:component, organization: organization, manifest_name: "paragraphs") }
      let!(:participatory_process) { create(:participatory_process, organization: organization) }
      let!(:author) { create(:user, :admin, organization: organization) }
      let!(:paragraph) { create(:paragraph, component: component, users: [author]) }
      let!(:paragraph_note) { build(:paragraph_note, paragraph: paragraph, author: author) }

      it { is_expected.to be_valid }
      it { is_expected.to be_versioned }

      it "has an associated author" do
        expect(paragraph_note.author).to be_a(Decidim::User)
      end

      it "has an associated paragraph" do
        expect(paragraph_note.paragraph).to be_a(Decidim::EnhancedTextwork::Paragraph)
      end
    end
  end
end
