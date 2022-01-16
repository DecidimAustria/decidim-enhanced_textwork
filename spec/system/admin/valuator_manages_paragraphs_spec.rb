# frozen_string_literal: true

require "spec_helper"

describe "Valuator manages paragraphs", type: :system do
  let(:manifest_name) { "paragraphs" }
  let!(:assigned_paragraph) { create :paragraph, component: current_component }
  let!(:unassigned_paragraph) { create :paragraph, component: current_component }
  let(:participatory_process) { create(:participatory_process, :with_steps, organization: organization) }
  let(:participatory_space_path) do
    decidim_admin_participatory_processes.edit_participatory_process_path(participatory_process)
  end
  let!(:user) { create :user, organization: organization }
  let!(:valuator_role) { create :participatory_process_user_role, role: :valuator, user: user, participatory_process: participatory_process }
  let!(:another_user) { create :user, organization: organization }
  let!(:another_valuator_role) { create :participatory_process_user_role, role: :valuator, user: another_user, participatory_process: participatory_process }

  include Decidim::ComponentPathHelper

  include_context "when managing a component as an admin"

  before do
    user.update(admin: false)

    create :valuation_assignment, paragraph: assigned_paragraph, valuator_role: valuator_role
    create :valuation_assignment, paragraph: assigned_paragraph, valuator_role: another_valuator_role

    visit current_path
  end

  context "when listing the paragraphs" do
    it "can only see the assigned paragraphs" do
      expect(page).to have_content(translated(assigned_paragraph.title))
      expect(page).to have_no_content(translated(unassigned_paragraph.title))
    end
  end

  context "when bulk unassigning valuators" do
    before do
      within find("tr", text: translated(assigned_paragraph.title)) do
        page.first(".js-paragraph-list-check").set(true)
      end

      click_button "Actions"
      click_button "Unassign from valuator"
    end

    it "can unassign themselves" do
      within "#js-form-unassign-paragraphs-from-valuator" do
        select user.name, from: :valuator_role_id
        page.find("button#js-submit-unassign-paragraphs-from-valuator").click
      end

      expect(page).to have_content("Valuator unassigned from paragraphs successfully")
    end

    it "cannot unassign others" do
      within "#js-form-unassign-paragraphs-from-valuator" do
        select another_user.name, from: :valuator_role_id
        page.find("button#js-submit-unassign-paragraphs-from-valuator").click
      end

      expect(page).to have_content("You are not authorized to perform this action")
    end
  end

  context "when in the paragraph page" do
    before do
      click_link translated(assigned_paragraph.title)
    end

    it "can only unassign themselves" do
      within "#valuators" do
        expect(page).to have_content(user.name)
        expect(page).to have_content(another_user.name)

        within find("li", text: another_user.name) do
          expect(page).to have_no_selector("a.red-icon")
        end

        within find("li", text: user.name) do
          expect(page).to have_selector("a.red-icon")
          accept_confirm do
            find("a.red-icon").click
          end
        end
      end

      expect(page).to have_content("successfully")
    end

    it "can leave paragraph notes" do
      expect(page).to have_content("Private notes")
      within ".add-comment" do
        fill_in "Note", with: " This is my note"
        click_button "Submit"
      end

      within ".comment-thread" do
        expect(page).to have_content("This is my note")
      end
    end

    it "can answer paragraphs" do
      within "form.edit_paragraph_answer" do
        choose "Accepted"
        fill_in_i18n_editor(
          :paragraph_answer_answer,
          "#paragraph_answer-answer-tabs",
          en: "This is my answer"
        )
        click_button "Answer"
      end
      expect(page).to have_content("successfully")
    end
  end
end
