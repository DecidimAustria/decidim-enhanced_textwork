# frozen_string_literal: true

require "spec_helper"

describe "Index Paragraph Notes", type: :system do
  let(:component) { create(:paragraph_component) }
  let(:organization) { component.organization }

  let(:manifest_name) { "paragraphs" }
  let(:paragraph) { create(:paragraph, component: component) }
  let(:participatory_space) { component.participatory_space }

  let(:body) { "New awesome body" }
  let(:paragraph_notes_count) { 5 }

  let!(:paragraph_notes) do
    create_list(
      :paragraph_note,
      paragraph_notes_count,
      paragraph: paragraph
    )
  end

  include_context "when managing a component as an admin"

  before do
    within find("tr", text: translated(paragraph.title)) do
      click_link "Answer paragraph"
    end
  end

  it "shows paragraph notes for the current paragraph" do
    paragraph_notes.each do |paragraph_note|
      expect(page).to have_content(paragraph_note.author.name)
      expect(page).to have_content(paragraph_note.body)
    end
    expect(page).to have_selector("form")
  end

  context "when the form has a text inside body" do
    it "creates a paragraph note ", :slow do
      within ".new_paragraph_note" do
        fill_in :paragraph_note_body, with: body

        find("*[type=submit]").click
      end

      expect(page).to have_admin_callout("successfully")

      within ".comment-thread .card:last-child" do
        expect(page).to have_content("New awesome body")
      end
    end
  end

  context "when the form hasn't text inside body" do
    let(:body) { nil }

    it "don't create a paragraph note", :slow do
      within ".new_paragraph_note" do
        fill_in :paragraph_note_body, with: body

        find("*[type=submit]").click
      end

      expect(page).to have_content("There's an error in this field.")
    end
  end
end
