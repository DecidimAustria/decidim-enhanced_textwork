# frozen_string_literal: true

require "spec_helper"
require "capybara/rspec"
require "warden/test/helpers"

RSpec.describe "Textwork reading and participation", type: :system do
  include Warden::Test::Helpers

  let(:organization) { create(:organization, host: "127.0.0.1", available_locales: %w(en de), default_locale: "en") }
  let(:space) { create(:participatory_process, organization:) }
  let(:component) { create(:textwork_component, :published, participatory_space: space) }
  let(:document) { create(:textwork_document, component:) }
  let(:admin) { create(:user, :admin, :confirmed, organization:) }
  let(:user) { create(:user, :confirmed, organization:) }
  let(:editor) { Decidim::EnhancedTextwork::EditDocument.new(document, admin) }
  let!(:heading) { editor.add(kind: "heading", body: "Our neighbourhood") }
  let!(:block) { editor.add(kind: "paragraph", body: "More trees and shade.") }
  let!(:second_heading) { editor.add(kind: "heading", body: "Next steps") }
  let!(:second_block) { editor.add(kind: "paragraph", body: "- Meetings\n- Reports") }
  let(:routes) { Decidim::EngineRouter.main_proxy(component) }

  before do
    driven_by :selenium, using: :headless_chrome, screen_size: [1440, 1000]
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    Capybara.enable_aria_label = true
    Capybara.server_host = "127.0.0.1"
    Capybara.app_host = "http://127.0.0.1"
    Capybara.always_include_port = true
    login_as user, scope: :user
    visit routes.document_path(document, locale: :en)
    click_button "Accept only essential" if page.has_button?("Accept only essential", wait: 1)
    page.execute_script("localStorage.setItem('PWAInstallPromptSeen','true')")
  end

  after do
    Warden.test_reset!
    Capybara.app_host = nil
    Capybara.always_include_port = false
  end

  it "toggles independent chapter likes and follows without navigating" do
    within "#block-#{heading.id}" do
      click_button "Agree"
      expect(page).to have_button("Agreed")
      click_button "Follow", exact: true
      expect(page).to have_button("Following – unfollow")
    end
    within "#block-#{second_heading.id}" do
      expect(page).to have_button("Agree")
      click_button "Agree"
      expect(page).to have_button("Agreed")
    end
    expect(heading.reload.likes_count).to eq(1)
    expect(second_heading.reload.likes_count).to eq(1)
  end

  it "switches comment resources, posts once and restores selection through history" do
    click_link "Comments on paragraph 1.1"
    within ".tw-panel" do
      expect(page).to have_content("Paragraph 1.1")
      find("textarea:not([disabled])").set("Please include drinking water.")
      click_button "Publish comment"
      expect(page).to have_content("Please include drinking water.")
    end
    click_link "Comments on paragraph 2.1"
    within ".tw-panel" do
      expect(page).to have_content("Paragraph 2.1")
      expect(page).to have_no_content("Please include drinking water.")
    end
    page.go_back
    within ".tw-panel" do
      expect(page).to have_content("Paragraph 1.1")
      expect(page).to have_content("Please include drinking water.")
    end
    expect(block.comments.where(author: user).count).to eq(1)
  end

  it "keeps the comment submit label readable when disabled and enabled" do
    click_link "Comments on paragraph 1.1"
    within ".tw-panel" do
      expect(page).to have_button("Publish comment", disabled: true)
      expect_readable_comment_submit
      find("textarea:not([disabled])").set("A readable action.")
      expect(page).to have_button("Publish comment", disabled: false)
      expect_readable_comment_submit
      find("textarea:not([disabled])").set("")
      expect(page).to have_button("Publish comment", disabled: true)
      expect_readable_comment_submit
    end
  end

  it "protects drafts, marks punctuation and submits a suggestion" do
    click_link "Suggestions for paragraph 1.1"
    fill_in "You are editing this paragraph", with: "More trees and shade!"
    expect(page).to have_css("[data-live-diff] ins", text: "!")
    click_button "Close", exact: true
    within ".tw-confirm" do
      expect(page).to have_content("Discard draft?")
      click_button "Keep editing"
    end
    expect(page).to have_field("You are editing this paragraph", with: "More trees and shade!")
    fill_in "Justification (optional)", with: "An emphatic suggestion."
    click_button "Submit suggestion"
    expect(page).to have_content("Your suggestion was submitted.")
    expect(block.suggestions.last!.original).to eq("More trees and shade!")
    within ".tw-panel" do
      expect(page).to have_content("An emphatic suggestion.")
      expect(page).to have_button("Edit")
    end
  end

  it "fits 390 and 320 pixels and keeps keyboard focus in the mobile sheet" do
    [390, 320].each do |width|
      page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width:, height: 844, deviceScaleFactor: 1, mobile: true)
      expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    end
    click_link "Comments on paragraph 1.1"
    expect(page).to have_css('.tw-panel[aria-modal="true"]')
    expect(page).to have_css("[data-panel-title]:focus")
    page.driver.browser.action.send_keys(:escape).perform
    expect(page).to have_no_css(".tw-panel")
    expect(page.evaluate_script("document.activeElement.getAttribute('aria-label')")).to eq("Comments on paragraph 1.1")
  end

  it "supports keyboard participation and enlarged text spacing" do
    find("#block-#{heading.id} .tw-like").send_keys(:enter)
    within("#block-#{heading.id}") { expect(page).to have_button("Agreed") }
    find_link("Comments on paragraph 1.1").send_keys(:enter)
    within ".tw-panel" do
      field = find("textarea:not([disabled])")
      field.send_keys("Keyboard contribution.")
      12.times do
        break if page.evaluate_script("document.activeElement.matches('button[type=submit]')")

        page.driver.browser.action.send_keys(:tab).perform
      end
      expect(page).to have_css('button[type="submit"]:focus', text: "Publish comment")
      page.driver.browser.action.send_keys(:enter).perform
      expect(page).to have_content("Keyboard contribution.")
    end
    page.driver.browser.action.send_keys(:escape).perform
    find_link("Suggestions for paragraph 1.1").send_keys(:enter)
    find_field("You are editing this paragraph").send_keys(:end, " Please prioritise schools.")
    find_button("Submit suggestion").send_keys(:enter)
    expect(page).to have_content("Your suggestion was submitted.")
    page.driver.browser.action.send_keys(:escape).perform
    page.execute_script(<<~JS)
      const spacing = document.createElement('style');
      spacing.textContent = '.tw-page * { line-height: 1.5 !important; letter-spacing: .12em !important; word-spacing: .16em !important; } .tw-page p { margin-bottom: 2em !important; }';
      document.head.append(spacing);
      document.documentElement.style.fontSize = '200%';
    JS
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    click_link "Comments on paragraph 2.1"
    expect(page).to have_button("Close", exact: true)
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
  end

  it "previews five suggestions and withdraws an own suggestion with confirmation" do
    5.times do |index|
      Decidim::EnhancedTextwork::SaveSuggestion.call(block, user, body: "More trees and shade, proposal #{index}.", expected_version: 1)
    end
    visit routes.document_path(document, locale: :en)
    click_link "Suggestions for paragraph 1.1"
    expect(page).to have_css(".tw-panel [data-suggestion]", count: 5)
    expect(page).to have_css("[data-preview]", text: "1 / 5")
    4.times { click_button "Next suggestion" }
    expect(page).to have_css("[data-preview]", text: "5 / 5")
    expect(page).to have_button("Next suggestion", disabled: true)
    within(all(".tw-panel [data-suggestion]").last) { click_button "Suggestion by #{user.name}" }
    expect(page).to have_current_path(/suggestion=/)
    within(".tw-panel") { click_button "Withdraw" }
    within(".tw-confirm") { click_button "Withdraw" }
    expect(page).to have_content("Your suggestion was withdrawn.")
    expect(block.suggestions.where(status: "withdrawn").count).to eq(1)
  end

  it "keeps only the last requested paragraph when switching quickly" do
    first = find_link("Comments on paragraph 1.1")
    second = find_link("Comments on paragraph 2.1")
    3.times do
      first.click
      second.click
    end
    within ".tw-panel" do
      expect(page).to have_content("Paragraph 2.1")
      expect(page).to have_css("[data-decidim-comments]", count: 1)
      expect(page).to have_css("textarea:not([disabled])", count: 1)
    end
  end

  it "passes automated WCAG A/AA checks in the reading view and comment panel" do
    page.execute_script(File.read(File.expand_path("../../node_modules/axe-core/axe.min.js", __dir__)))
    [nil, "Comments on paragraph 1.1"].each do |action|
      click_link action if action
      expect(page).to have_css(".tw-panel [data-decidim-comments]") if action
      violations = page.driver.browser.execute_async_script(<<~JS)
        const done = arguments[0];
        axe.run(document.querySelector('.tw-page'), {runOnly: {type:'tag', values:['wcag2a','wcag2aa','wcag21aa','wcag22aa','best-practice']}})
          .then(result => done(result.violations.map(issue => ({id:issue.id, targets:issue.nodes.map(node => node.target)}))));
      JS
      expect(violations).to eq([])
    end
  end

  # Disabled controls are skipped by axe's contrast rule. Measure the visible
  # label separately, compositing alpha/opacity against its rendered background.
  def expect_readable_comment_submit
    # Core animates color changes; assert the settled state without a fixed sleep.
    page.document.synchronize(errors: [RSpec::Expectations::ExpectationNotMetError]) do
      expect(comment_submit_contrast).to be >= 4.5
    end
  end

  def comment_submit_contrast
    page.evaluate_script(<<~'JS')
      (() => {
        const button = document.querySelector('.tw-panel .comment__form-submit button[type="submit"]');
        const label = button.querySelector('span');
        const color = value => value.match(/[\d.]+/g).map(Number);
        const blend = (front, back, opacity = 1) => {
          const alpha = (front[3] ?? 1) * opacity;
          return front.slice(0, 3).map((value, index) => value * alpha + back[index] * (1 - alpha));
        };
        const ancestors = [];
        for (let element = button.parentElement; element; element = element.parentElement) ancestors.unshift(element);
        let surface = [255, 255, 255];
        let opacity = 1;
        ancestors.forEach(element => {
          const style = getComputedStyle(element);
          surface = blend(color(style.backgroundColor), surface);
          opacity *= Number(style.opacity);
        });
        const style = getComputedStyle(button);
        const background = blend(color(style.backgroundColor), surface);
        const foreground = blend(color(getComputedStyle(label).color), background);
        opacity *= Number(style.opacity);
        const luminance = rgb => rgb.map(value => {
          const channel = value / 255;
          return channel <= 0.04045 ? channel / 12.92 : ((channel + 0.055) / 1.055) ** 2.4;
        }).reduce((total, value, index) => total + value * [0.2126, 0.7152, 0.0722][index], 0);
        const light = luminance(blend([...foreground, 1], surface, opacity));
        const dark = luminance(blend([...background, 1], surface, opacity));
        return (Math.max(light, dark) + 0.05) / (Math.min(light, dark) + 0.05);
      })()
    JS
  end
end
