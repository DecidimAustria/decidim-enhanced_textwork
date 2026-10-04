# frozen_string_literal: true

require "spec_helper"
require "capybara/rspec"
require "warden/test/helpers"

RSpec.describe "Discussing a participatory text", type: :system do
  include Warden::Test::Helpers
  let(:organization) { create(:organization, name: { en: "Textwork demo" }, host: "127.0.0.1", available_locales: %w(en de), default_locale: "en") }
  let(:space) { create(:participatory_process, organization:, title: { en: "A greener neighbourhood" }) }
  let(:component) do
    create(:proposal_component, :published, participatory_space: space, name: { en: "Our neighbourhood plan" },
           settings: { participatory_texts_enabled: true, enhanced_textwork_enabled: true })
  end
  let!(:paragraph) do
    create(:proposal, component:, title: { en: "1" }, body: { en: "Our neighbourhood needs more shade and places to sit." }, participatory_text_level: "article")
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

  it "supports and withdraws support through the core vote controls" do
    component.update!(default_step_settings: { votes_enabled: true })
    user = create(:user, :confirmed, organization:)
    login_as user, scope: :user
    visit Decidim::EngineRouter.main_proxy(component).textwork_path(locale: :en)
    click_button "Accept only essential"
    within "#proposal-#{paragraph.id}-vote-button" do
      find("button").click
      expect(page).to have_css("#vote_button-#{paragraph.id}")
      expect(paragraph.votes.where(author: user)).to exist
      find("button").click
      expect(page).not_to have_css("#vote_button-#{paragraph.id}")
      expect(paragraph.votes.where(author: user)).not_to exist
    end
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

  it "imports editor content and publishes it through the core admin preview" do
    user = create(:user, :admin, :confirmed, organization:)
    login_as user, scope: :user
    empty_component = create(:proposal_component, participatory_space: space,
                             settings: { participatory_texts_enabled: true, enhanced_textwork_enabled: true })
    admin_routes = Decidim::EngineRouter.admin_proxy(empty_component)
    visit admin_routes.textwork_path(locale: :en)
    find('input[name="import[title_en]"]').set("Community plan")
    find('[contenteditable="true"]').set("A new public garden for our neighbourhood.")
    click_button "Import text"
    expect(page).to have_content("The document was imported")
    expect(page).to have_button("Publish document")
    click_button "Publish document"
    expect(page).to have_content("All proposals have been published.")
    expect(Decidim::Proposals::Proposal.where(component: empty_component).published.count).to eq(1)
  end

  it "opens the paragraph's core comments in a responsive sidebar" do
    create(:comment, commentable: paragraph, body: { en: "Please include trees near the playground." })
    visit Decidim::EngineRouter.main_proxy(component).proposals_path(locale: :en)
    expect(page).to have_content("Our neighbourhood needs more shade")
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
end
