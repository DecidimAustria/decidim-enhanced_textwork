# frozen_string_literal: true

require "spec_helper"

module Decidim::EnhancedTextwork
  describe ReportedContentCell, type: :cell do
    controller Decidim::EnhancedTextwork::ParagraphsController

    let!(:paragraph) { create(:paragraph, title: { "en" => "a nice title" }, body: { "en" => "let's do this!" }) }

    context "when rendering" do
      it "renders the paragraph's title and body" do
        html = cell("decidim/reported_content", paragraph).call
        expect(html).to have_content("a nice title")
        expect(html).to have_content("let's do this!")
      end
    end
  end
end
