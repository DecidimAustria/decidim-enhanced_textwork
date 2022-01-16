# frozen_string_literal: true

require "spec_helper"

describe "Admin edits paragraphs", type: :system do
  let(:manifest_name) { "paragraphs" }
  let(:organization) { participatory_process.organization }
  let!(:user) { create :user, :admin, :confirmed, organization: organization }
  let!(:paragraph) { create :paragraph, :official, component: component }
  let(:creation_enabled?) { true }

  include_context "when managing a component as an admin"

  before do
    component.update!(
      step_settings: {
        component.participatory_space.active_step.id => {
          creation_enabled: creation_enabled?
        }
      }
    )
  end

  describe "editing an official paragraph" do
    let(:new_title) { "This is my paragraph new title" }
    let(:new_body) { "This is my paragraph new body" }

    it "can be updated" do
      visit_component_admin

      find("a.action-icon--edit-paragraph").click
      expect(page).to have_content "Update paragraph"

      fill_in_i18n :paragraph_title, "#paragraph-title-tabs", en: new_title
      fill_in_i18n_editor :paragraph_body, "#paragraph-body-tabs", en: new_body
      click_button "Update"

      preview_window = window_opened_by { find("a.action-icon--preview").click }

      within_window preview_window do
        expect(page).to have_content(new_title)
        expect(page).to have_content(new_body)
      end
    end

    context "when the paragraph has some votes" do
      before do
        create :paragraph_vote, paragraph: paragraph
      end

      it "doesn't let the user edit it" do
        visit_component_admin

        expect(page).to have_content(translated(paragraph.title))
        expect(page).to have_no_css("a.action-icon--edit-paragraph")
        visit current_path + "paragraphs/#{paragraph.id}/edit"

        expect(page).to have_content("not authorized")
      end
    end

    context "when the paragraph has attachement" do
      let!(:component) do
        create(:paragraph_component,
               :with_creation_enabled,
               :with_attachments_allowed,
               manifest: manifest,
               participatory_space: participatory_process)
      end

      let!(:paragraph) do
        create(:paragraph,
               :official,
               component: component,
               title: "Paragraph with attachments",
               body: "This is my paragraph and I want to upload attachments.")
      end

      let!(:document) { create(:attachment, :with_pdf, attached_to: paragraph) }

      it "can be remove attachment" do
        visit_component_admin
        find("a.action-icon--edit-paragraph").click
        find("input#paragraph_attachment_delete_file").set(true)
        find(".form-general-submit .button").click

        expect(page).to have_content("Paragraph successfully updated.")

        visit_component_admin
        find("a.action-icon--edit-paragraph").click
        expect(page).to have_no_content("Current file")
      end
    end
  end

  describe "editing a non-official paragraph" do
    let!(:paragraph) { create :paragraph, users: [user], component: component }

    it "renders an error" do
      visit_component_admin

      expect(page).to have_content(translated(paragraph.title))
      expect(page).to have_no_css("a.action-icon--edit-paragraph")
      visit current_path + "paragraphs/#{paragraph.id}/edit"

      expect(page).to have_content("not authorized")
    end
  end
end
