# frozen_string_literal: true

require "spec_helper"

describe "Paragraphs in process home", type: :system do
  include_context "with a component"
  let(:manifest_name) { "paragraphs" }
  let(:paragraphs_count) { 2 }
  let(:highlighted_paragraphs) { paragraphs_count * 2 }

  before do
    allow(Decidim::EnhancedTextwork.config)
      .to receive(:participatory_space_highlighted_paragraphs_limit)
      .and_return(highlighted_paragraphs)
  end

  context "when there are no paragraphs" do
    it "does not show the highlighted paragraphs section" do
      visit resource_locator(participatory_process).path
      expect(page).not_to have_css(".highlighted_paragraphs")
    end
  end

  context "when there are paragraphs" do
    let!(:paragraphs) { create_list(:paragraph, paragraphs_count, component: component) }
    let!(:drafted_paragraphs) { create_list(:paragraph, paragraphs_count, :draft, component: component) }
    let!(:hidden_paragraphs) { create_list(:paragraph, paragraphs_count, :hidden, component: component) }
    let!(:withdrawn_paragraphs) { create_list(:paragraph, paragraphs_count, :withdrawn, component: component) }

    it "shows the highlighted paragraphs section" do
      visit resource_locator(participatory_process).path

      within ".highlighted_paragraphs" do
        expect(page).to have_css(".card--paragraph", count: paragraphs_count)

        paragraphs_titles = paragraphs.map(&:title).map { |title| translated(title) }
        drafted_paragraphs_titles = drafted_paragraphs.map(&:title).map { |title| translated(title) }
        hidden_paragraphs_titles = hidden_paragraphs.map(&:title).map { |title| translated(title) }
        withdrawn_paragraphs_titles = withdrawn_paragraphs.map(&:title).map { |title| translated(title) }

        highlighted_paragraphs = page.all(".card--paragraph .card__title").map(&:text)
        expect(paragraphs_titles).to include(*highlighted_paragraphs)
        expect(drafted_paragraphs_titles).not_to include(*highlighted_paragraphs)
        expect(hidden_paragraphs_titles).not_to include(*highlighted_paragraphs)
        expect(withdrawn_paragraphs_titles).not_to include(*highlighted_paragraphs)
      end
    end

    context "and there are more paragraphs than those that can be shown" do
      let!(:paragraphs) { create_list(:paragraph, highlighted_paragraphs + 2, component: component) }

      it "shows the amount of paragraphs configured" do
        visit resource_locator(participatory_process).path

        within ".highlighted_paragraphs" do
          expect(page).to have_css(".card--paragraph", count: highlighted_paragraphs)

          paragraphs_titles = paragraphs.map(&:title).map { |title| translated(title) }
          highlighted_paragraphs = page.all(".card--paragraph .card__title").map(&:text)
          expect(paragraphs_titles).to include(*highlighted_paragraphs)
        end
      end
    end
  end
end
