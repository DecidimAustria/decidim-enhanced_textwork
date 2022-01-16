# frozen_string_literal: true

shared_examples "import paragraphs" do
  let!(:paragraphs) { create_list :paragraph, 3, :accepted, component: origin_component }
  let!(:rejected_paragraphs) { create_list :paragraph, 3, :rejected, component: origin_component }
  let!(:origin_component) { create :paragraph_component, participatory_space: current_component.participatory_space }
  include Decidim::ComponentPathHelper

  it "imports paragraphs from one component to another" do
    fill_form

    confirm_flash_message

    paragraphs.each do |paragraph|
      expect(page).to have_content(paragraph.title["en"])
    end

    confirm_current_path
  end

  it "imports paragraphs from one component to another by keeping the authors" do
    fill_form(keep_authors: true)

    confirm_flash_message

    paragraphs.each do |paragraph|
      expect(page).to have_content(paragraph.title["en"])
    end

    confirm_current_path
  end

  it "imports paragraphs from a csv file" do
    find(".imports.dropdown").click
    click_link "Import from a file"

    attach_file("import_file", Decidim::Dev.asset("import_paragraphs.csv"))

    click_button "Import"

    confirm_flash_message
    confirm_current_path
  end

  it "imports paragraphs from a json file" do
    find(".imports.dropdown").click
    click_link "Import from a file"

    attach_file("import_file", Decidim::Dev.asset("import_paragraphs.json"))

    click_button "Import"

    confirm_flash_message
    confirm_current_path
  end

  it "imports paragraphs from a excel file" do
    find(".imports.dropdown").click
    click_link "Import from a file"

    attach_file("import_file", Decidim::Dev.asset("import_paragraphs.xlsx"))

    click_button "Import"

    confirm_flash_message
    confirm_current_path
  end

  def fill_form(keep_authors: false)
    find(".imports.dropdown").click
    click_link "Import from another component"

    within ".import_paragraphs" do
      select origin_component.name["en"], from: "Origin component"
      check "Accepted"
      check "Keep original authors" if keep_authors
      check "Import paragraphs"
    end

    click_button "Import paragraphs"
  end

  def confirm_flash_message
    expect(page).to have_content("3 paragraphs successfully imported")
  end

  def confirm_current_path
    expect(page).to have_current_path(manage_component_path(current_component))
  end
end
