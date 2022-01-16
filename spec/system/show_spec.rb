# frozen_string_literal: true

require "spec_helper"

describe "show", type: :system do
  include_context "with a component"
  let(:manifest_name) { "paragraphs" }

  let!(:paragraph) { create(:paragraph, component: component) }

  before do
    visit_component
    click_link paragraph.title[I18n.locale.to_s], class: "card__link"
  end

  context "when shows the paragraph component" do
    it "shows the paragraph title" do
      expect(page).to have_content paragraph.title[I18n.locale.to_s]
    end

    it_behaves_like "going back to list button"
  end
end
