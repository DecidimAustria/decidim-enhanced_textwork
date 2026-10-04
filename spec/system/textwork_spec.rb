# frozen_string_literal: true

require "spec_helper"
require "capybara/rspec"
require "warden/test/helpers"

RSpec.describe "Discussing a participatory text", type: :system do
  include Warden::Test::Helpers
  let(:organization) { create(:organization, name: { en: "Textwork demo" }, host: "127.0.0.1", available_locales: %w(en de), default_locale: "en") }
  let(:space) { create(:participatory_process, organization:, title: { en: "A greener neighbourhood" }) }
  let(:component) do
    create(:textwork_component, :published, participatory_space: space, name: { en: "Our neighbourhood plan" })
  end
  let!(:paragraph) do
    create(:textwork_section, document: create(:textwork_document, component:))
  end

  before do
    driven_by :selenium, using: :headless_chrome, screen_size: [1440, 1000]
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    Capybara.server_host = "127.0.0.1"
    Capybara.app_host = "http://127.0.0.1"
    Capybara.always_include_port = true
  end

  after do
    Warden.test_reset!
    Capybara.app_host = nil
    Capybara.always_include_port = false
  end

  it "supports and withdraws support with the independent support controls" do
    user = create(:user, :confirmed, organization:)
    login_as user, scope: :user
    visit Decidim::EngineRouter.main_proxy(component).textwork_path(locale: :en)
    click_button "Accept only essential"
    click_button "Support this version"
    expect(page).to have_button("Withdraw support")
    expect(paragraph.current_revision.supports.where(author: user)).to exist
    click_button "Withdraw support"
    expect(page).to have_button("Support this version")
    expect(paragraph.current_revision.supports.where(author: user)).not_to exist
  end

  it "posts a comment from the sidebar using the core comment form" do
    user = create(:user, :confirmed, organization:)
    login_as user, scope: :user
    visit Decidim::EngineRouter.main_proxy(component).textwork_path(locale: :en, paragraph_id: paragraph.id)
    click_button "Accept only essential"
    within "#textwork-discussion" do
      find("textarea").set("Please add a shaded bench.")
      find('button[type="submit"]').click
      expect(page).to have_content("Please add a shaded bench.")
    end
    expect(Decidim::Comments::Comment.where(root_commentable: paragraph, author: user).count).to eq(1)
  end

  it "imports editor content and publishes it through Textwork administration" do
    user = create(:user, :admin, :confirmed, organization:)
    login_as user, scope: :user
    empty_component = create(:textwork_component, participatory_space: space)
    admin_routes = Decidim::EngineRouter.admin_proxy(empty_component)
    visit admin_routes.textwork_path(locale: :en)
    find('input[name="import[title_en]"]').set("Community plan")
    find('[contenteditable="true"]').set("A new public garden for our neighbourhood.")
    click_button "Import text"
    expect(page).to have_content("The document was imported")
    expect(page).to have_button("Publish document")
    click_button "Publish document"
    expect(page).to have_link("Review and publish paragraphs")
    expect(Decidim::EnhancedTextwork::Document.find_by!(component: empty_component).published?).to be(true)
  end

  it "opens the paragraph's core comments in a responsive sidebar" do
    create(:comment, commentable: paragraph, body: { en: "Please include trees near the playground." })
    visit Decidim::EngineRouter.main_proxy(component).textwork_path(locale: :en)
    expect(page).to have_content("More trees")
    click_button "Accept only essential"
    click_link "Discuss (1 comment)"
    within "#textwork-discussion" do
      expect(page).to have_content("Please include trees near the playground.")
    end
    expect(page.evaluate_script("getComputedStyle(document.querySelector('.textwork')).display")).to eq("grid")
    page.save_screenshot(File.expand_path("../../tmp/textwork-desktop.png", __dir__))
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: true)
    expect(page.evaluate_script("window.innerWidth")).to eq(390)
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    page.save_screenshot(File.expand_path("../../tmp/textwork-mobile.png", __dir__))
  end
  it "submits an amendment with the editor and lets an administrator accept it without transferring supports" do
    user = create(:user, :confirmed, organization:)
    admin = create(:user, :admin, :confirmed, organization:)
    original = paragraph.current_revision
    original.supports.create!(author: user)
    routes = Decidim::EngineRouter.main_proxy(component)
    login_as user, scope: :user
    visit routes.new_section_amendment_path(paragraph, locale: :en)
    click_button "Accept only essential"
    find('[contenteditable="true"]').set("Trees and shaded benches near the playground.")
    fill_in "Reason for the change", with: "Shade during summer"
    click_button "Submit amendment"
    expect(page).to have_content("Shade during summer")
    expect(page).to have_content("Pending")
    amendment = paragraph.amendments.last!
    within "#comments" do
      find("textarea").set("This would help families.")
      find('button[type="submit"]').click
      expect(page).to have_content("This would help families.")
    end
    logout(:user)
    login_as admin, scope: :user
    visit routes.amendment_path(amendment, locale: :en)
    # Core can intercept the next click for its browser installation prompt.
    page.execute_script("localStorage.setItem('pwaInstallPromptSeen', 'true')")
    fill_in "Reason for the decision", with: "Included in the plan"
    click_button "Accept amendment"
    expect(page).to have_content("Accepted")
    expect(page).to have_content("Included in the plan")
    expect(paragraph.reload.current_revision.body["en"]).to include("shaded benches")
    expect(paragraph.current_revision.supports.count).to eq(0)
    expect(original.reload.supports.count).to eq(1)
    expect(Decidim::ActionLog.where(resource: amendment, action: "accepted")).to exist
  end
end
