# frozen_string_literal: true

require "spec_helper"

describe "Index paragraphs", type: :system do
  include_context "with a component"
  let(:manifest_name) { "paragraphs" }

  context "when there are paragraphs" do
    let!(:paragraphs) { create_list(:paragraph, 3, component: component) }

    it "doesn't display empty message" do
      visit_component

      expect(page).to have_no_content("There is no paragraph yet")
    end
  end

  context "when there are no paragraphs" do
    context "when there are no filters" do
      it "shows generic empty message" do
        visit_component

        expect(page).to have_content("There is no paragraph yet")
      end
    end

    context "when there are filters" do
      let!(:paragraphs) { create(:paragraph, :with_answer, :accepted, component: component) }

      it "shows filters empty message" do
        visit_component

        uncheck "Accepted"

        expect(page).to have_content("There isn't any paragraph with this criteria")
      end
    end
  end
end
