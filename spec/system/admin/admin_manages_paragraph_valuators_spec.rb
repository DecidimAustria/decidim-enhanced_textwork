# frozen_string_literal: true

require "spec_helper"

describe "Admin manages paragraphs valuators", type: :system do
  let(:manifest_name) { "paragraphs" }
  let!(:paragraph) { create :paragraph, component: current_component }
  let!(:reportables) { create_list(:paragraph, 3, component: current_component) }
  let(:participatory_process) { create(:participatory_process, :with_steps, organization: organization) }
  let(:participatory_space_path) do
    decidim_admin_participatory_processes.edit_participatory_process_path(participatory_process)
  end
  let!(:valuator) { create :user, organization: organization }
  let!(:valuator_role) { create :participatory_process_user_role, role: :valuator, user: valuator, participatory_process: participatory_process }

  include Decidim::ComponentPathHelper

  include_context "when managing a component as an admin"

  context "when assigning to a valuator" do
    before do
      visit current_path

      within find("tr", text: translated(paragraph.title)) do
        page.first(".js-paragraph-list-check").set(true)
      end

      click_button "Actions"
      click_button "Assign to valuator"
    end

    it "shows the component select" do
      expect(page).to have_css("#js-form-assign-paragraphs-to-valuator select", count: 1)
    end

    it "shows an update button" do
      expect(page).to have_css("button#js-submit-assign-paragraphs-to-valuator", count: 1)
    end

    context "when submitting the form" do
      before do
        within "#js-form-assign-paragraphs-to-valuator" do
          select valuator.name, from: :valuator_role_id
          page.find("button#js-submit-assign-paragraphs-to-valuator").click
        end
      end

      it "assigns the paragraphs to the valuator" do
        expect(page).to have_content("Paragraphs assigned to a valuator successfully")

        within find("tr", text: translated(paragraph.title)) do
          expect(page).to have_selector("td.valuators-count", text: 1)
        end
      end
    end
  end

  context "when filtering paragraphs by assigned valuator" do
    let!(:unassigned_paragraph) { create :paragraph, component: component }
    let(:assigned_paragraph) { paragraph }

    before do
      create :valuation_assignment, paragraph: paragraph, valuator_role: valuator_role

      visit current_path
    end

    it "only shows the paragraphs assigned to the selected valuator" do
      expect(page).to have_content(translated(assigned_paragraph.title))
      expect(page).to have_content(translated(unassigned_paragraph.title))

      within ".filters__section" do
        find("a.dropdown", text: "Filter").hover
        find("a", text: "Assigned to valuator").hover
        find("a", text: valuator.name).click
      end

      expect(page).to have_content(translated(assigned_paragraph.title))
      expect(page).to have_no_content(translated(unassigned_paragraph.title))
    end
  end

  context "when unassigning valuators from a paragraph from the paragraphs index page" do
    let(:assigned_paragraph) { paragraph }

    before do
      create :valuation_assignment, paragraph: paragraph, valuator_role: valuator_role

      visit current_path

      within find("tr", text: translated(paragraph.title)) do
        page.first(".js-paragraph-list-check").set(true)
      end

      click_button "Actions"
      click_button "Unassign from valuator"
    end

    it "shows the component select" do
      expect(page).to have_css("#js-form-unassign-paragraphs-from-valuator select", count: 1)
    end

    it "shows an update button" do
      expect(page).to have_css("button#js-submit-unassign-paragraphs-from-valuator", count: 1)
    end

    context "when submitting the form" do
      before do
        within "#js-form-unassign-paragraphs-from-valuator" do
          select valuator.name, from: :valuator_role_id
          page.find("button#js-submit-unassign-paragraphs-from-valuator").click
        end
      end

      it "unassigns the paragraphs to the valuator" do
        expect(page).to have_content("Valuator unassigned from paragraphs successfully")

        within find("tr", text: translated(paragraph.title)) do
          expect(page).to have_selector("td.valuators-count", text: 0)
        end
      end
    end
  end

  context "when unassigning valuators from a paragraph from the paragraph show page" do
    let(:assigned_paragraph) { paragraph }

    before do
      create :valuation_assignment, paragraph: paragraph, valuator_role: valuator_role

      visit current_path

      find("a", text: translated(paragraph.title)).click
    end

    it "can unassign a valuator" do
      within "#valuators" do
        expect(page).to have_content(valuator.name)

        accept_confirm do
          find("a.red-icon").click
        end
      end

      expect(page).to have_content("Valuator unassigned from paragraphs successfully")

      expect(page).to have_no_selector("#valuators")
    end
  end
end
