# frozen_string_literal: true

require "spec_helper"

describe Decidim::EnhancedTextwork::SimilarParagraphs do
  let(:organization) { create(:organization, enable_machine_translations: enabled) }
  let(:participatory_process) { create(:participatory_process, organization: organization) }
  let(:component) { create(:paragraph_component, participatory_space: participatory_process) }

  let!(:paragraph) { create(:paragraph, component: component, body: paragraph_body, title: paragraph_title) }
  let!(:matching_paragraph) { create(:paragraph, component: component, body: matching_body, title: matching_title) }
  let!(:missed_paragraph) { create(:paragraph, component: component, body: missing_body, title: missing_title) }

  context "when machine_translations is disabled" do
    let(:enabled) { false }
    let(:paragraph_body) { "100% match for body" }
    let(:paragraph_title) { "100% match for title" }
    let(:matching_body) { paragraph_body }
    let(:matching_title) { paragraph_title }
    let(:missing_body) { "Some Random body" }
    let(:missing_title) { "Some random title" }

    it "finds the similar paragraph" do
      Decidim::EnhancedTextwork.similarity_threshold = 0.85
      expect(described_class.for([component], paragraph).map(&:id).sort).to eq([paragraph.id, matching_paragraph.id])
    end

    it "counts just the available paragraphs" do
      Decidim::EnhancedTextwork.similarity_threshold = 0.85
      expect(described_class.for([component], paragraph).size).to eq(2)
    end
  end

  context "when machine_translations is disabled" do
    let(:enabled) { true }
    let(:paragraph_body) { { "en": "100% match for body" } }
    let(:paragraph_title) { { "en": "100% match for title" } }
    let(:matching_body) { missing_body.merge({ machine_translations: paragraph_body }) }
    let(:matching_title) { missing_title.merge({ machine_translations: paragraph_title }) }
    let(:missing_body) { { "ro": "Some Random body" } }
    let(:missing_title) { { "ro": "Some random title" } }

    it "finds the similar paragraph" do
      Decidim::EnhancedTextwork.similarity_threshold = 0.85
      I18n.with_locale(:en) do
        expect(described_class.for([component], paragraph).map(&:id).sort).to eq([paragraph.id, matching_paragraph.id])
      end
    end

    it "counts just the available paragraphs" do
      Decidim::EnhancedTextwork.similarity_threshold = 0.85
      I18n.with_locale(:en) do
        expect(described_class.for([component], paragraph).size).to eq(2)
      end
    end
  end
end
