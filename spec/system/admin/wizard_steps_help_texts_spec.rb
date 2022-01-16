# frozen_string_literal: true

require "spec_helper"

describe "Manage paragraph wizard steps help texts", type: :system do
  include_context "when admin manages paragraphs"

  before do
    current_component.update!(
      step_settings: {
        current_component.participatory_space.active_step.id => {
          creation_enabled: true
        }
      }
    )
  end

  let!(:paragraph) { create(:paragraph, component: current_component) }
  let!(:paragraph_similar) { create(:paragraph, component: current_component, title: "This paragraph is to ensure a similar exists") }
  let!(:paragraph_draft) { create(:paragraph, :draft, component: current_component, title: "This paragraph has a similar") }

  it "customize the help text for step 1 of the paragraph wizard" do
    visit edit_component_path(current_component)

    fill_in_i18n_editor(
      :component_settings_paragraph_wizard_step_1_help_text,
      "#global-settings-paragraph_wizard_step_1_help_text-tabs",
      en: "This is the first step of the Paragraph creation wizard.",
      es: "Este es el primer paso del asistente de creación de propuestas.",
      ca: "Aquest és el primer pas de l'assistent de creació de la proposta."
    )

    click_button "Update"

    visit new_paragraph_path(current_component)
    within ".paragraph_wizard_help_text" do
      expect(page).to have_content("This is the first step of the Paragraph creation wizard.")
    end
  end

  it "customize the help text for step 2 of the paragraph wizard" do
    visit edit_component_path(current_component)

    fill_in_i18n_editor(
      :component_settings_paragraph_wizard_step_2_help_text,
      "#global-settings-paragraph_wizard_step_2_help_text-tabs",
      en: "This is the second step of the Paragraph creation wizard.",
      es: "Este es el segundo paso del asistente de creación de propuestas.",
      ca: "Aquest és el segon pas de l'assistent de creació de la proposta."
    )

    click_button "Update"

    create(:paragraph, title: "More sidewalks and less roads", body: "Cities need more people, not more cars", component: component)
    create(:paragraph, title: "More trees and parks", body: "Green is always better", component: component)
    visit_component
    click_link "New paragraph"
    within ".new_paragraph" do
      fill_in :paragraph_title, with: "More sidewalks and less roads"
      fill_in :paragraph_body, with: "Cities need more people, not more cars"

      find("*[type=submit]").click
    end

    within ".paragraph_wizard_help_text" do
      expect(page).to have_content("This is the second step of the Paragraph creation wizard.")
    end
  end

  it "customize the help text for step 3 of the paragraph wizard" do
    visit edit_component_path(current_component)

    fill_in_i18n_editor(
      :component_settings_paragraph_wizard_step_3_help_text,
      "#global-settings-paragraph_wizard_step_3_help_text-tabs",
      en: "This is the third step of the Paragraph creation wizard.",
      es: "Este es el tercer paso del asistente de creación de propuestas.",
      ca: "Aquest és el tercer pas de l'assistent de creació de la proposta."
    )

    click_button "Update"

    visit_component
    click_link "New paragraph"
    within ".new_paragraph" do
      fill_in :paragraph_title, with: "More sidewalks and less roads"
      fill_in :paragraph_body, with: "Cities need more people, not more cars"

      find("*[type=submit]").click
    end

    within ".paragraph_wizard_help_text" do
      expect(page).to have_content("This is the third step of the Paragraph creation wizard.")
    end
  end

  it "customize the help text for step 4 of the paragraph wizard" do
    visit edit_component_path(current_component)

    fill_in_i18n_editor(
      :component_settings_paragraph_wizard_step_4_help_text,
      "#global-settings-paragraph_wizard_step_4_help_text-tabs",
      en: "This is the fourth step of the Paragraph creation wizard.",
      es: "Este es el cuarto paso del asistente de creación de propuestas.",
      ca: "Aquest és el quart pas de l'assistent de creació de la proposta."
    )

    click_button "Update"

    visit preview_paragraph_path(current_component, paragraph_draft)
    within ".paragraph_wizard_help_text" do
      expect(page).to have_content("This is the fourth step of the Paragraph creation wizard.")
    end
  end

  private

  def new_paragraph_path(current_component)
    Decidim::EngineRouter.main_proxy(current_component).new_paragraph_path(current_component.id)
  end

  def complete_paragraph_path(current_component, paragraph)
    Decidim::EngineRouter.main_proxy(current_component).complete_paragraph_path(paragraph)
  end

  def preview_paragraph_path(current_component, paragraph)
    "#{Decidim::EngineRouter.main_proxy(current_component).paragraph_path(paragraph)}/preview"
  end
end
