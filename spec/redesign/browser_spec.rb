# frozen_string_literal: true

require "spec_helper"
require "capybara/rspec"
require "warden/test/helpers"

RSpec.describe "Textwork reading and participation", type: :system do
  include Warden::Test::Helpers

  let(:organization) { create(:organization, host: "127.0.0.1", available_locales: %w(en de), default_locale: "en") }
  let(:space) { create(:participatory_process, organization:) }
  let(:component) { create(:textwork_component, :published, participatory_space: space) }
  let(:document) { create(:textwork_document, component:, published_at: nil) }
  let(:admin) { create(:user, :admin, :confirmed, organization:) }
  let(:user) { create(:user, :confirmed, organization:) }
  let(:editor) { Decidim::EnhancedTextwork::EditDocument.new(document, admin) }
  let!(:heading) { editor.add(kind: "heading", body: "Our neighbourhood") }
  let!(:block) { editor.add(kind: "paragraph", body: "More trees and shade.") }
  let!(:second_heading) { editor.add(kind: "heading", body: "Next steps") }
  let!(:second_block) { editor.add(kind: "paragraph", body: "- Meetings\n- Reports") }
  let(:routes) { Decidim::EngineRouter.main_proxy(component) }

  before do
    document.publish!
    driven_by :selenium, using: :headless_chrome, screen_size: [1440, 1000]
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    page.driver.browser.manage.window.resize_to(1440, 1042)
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

  def open_paragraph(record = block)
    find("[data-block-pill='#{record.id}']").click
    expect(page).to have_css("[data-panel-block='#{record.id}']")
  end

  def propose(count = 1)
    count.times do |index|
      Decidim::EnhancedTextwork::SaveSuggestion.call(block, user, body: "More trees and shade, proposal #{index}.", expected_version: 1)
    end
    visit routes.document_path(document, locale: :en)
    open_paragraph
  end

  it "keeps the document fixed while opening, liking and closing a paragraph" do
    expect(page).to have_css("[data-overview]")
    expect(page).to have_no_css(".tw-heading .tw-interactions")
    left = page.evaluate_script("document.querySelector('.tw-document').getBoundingClientRect().width")
    open_paragraph
    within(".tw-panel") do
      find("[data-kind=like]").click
      expect(page).to have_css("[data-interaction-label]", text: "Agreed")
      click_button "Close", exact: true
    end
    expect(page).to have_css("[data-overview]")
    expect(page).to have_button("← Back to paragraph 1.1")
    expect(page.evaluate_script("document.querySelector('.tw-document').getBoundingClientRect().width")).to eq(left)
    expect(block.reload.likes_count).to eq(1)
    expect(page).to have_css("[data-block-pill='#{block.id}']:focus")
    capture_screen("/private/tmp/textwork-desktop-overview.png")
  end

  it "switches Core comment resources, posts once and restores selection through history" do
    open_paragraph
    within ".tw-panel" do
      find("textarea:not([disabled])").set("Please include drinking water.")
      click_button "Publish comment"
      expect(page).to have_content("Please include drinking water.")
    end
    open_paragraph(second_block)
    within(".tw-panel") { expect(page).to have_no_content("Please include drinking water.") }
    page.go_back
    expect(page).to have_css("[data-panel-block='#{block.id}']", text: "Please include drinking water.")
    expect(block.comments.where(author: user).count).to eq(1)
  end

  it "separates fixed document surfaces from instance colors and puts follow below the summary" do
    expect(page).to have_css(".tw-intro .tw-follow")
    initial = page.evaluate_script(<<~JS)
      (() => {
        const panel = getComputedStyle(document.querySelector('.tw-panel'));
        return {
          background: panel.backgroundColor, border: panel.borderTopWidth, shadow: panel.boxShadow,
          follow: document.querySelector('.tw-follow').getBoundingClientRect().top,
          summary: document.querySelector('.tw-summary').getBoundingClientRect().bottom
        };
      })()
    JS
    expect(initial.values_at("background", "border", "shadow")).to eq(["rgb(244, 246, 248)", "0px", "none"])
    expect(initial["follow"]).to be >= initial["summary"]
    open_paragraph
    expect(page.evaluate_script("getComputedStyle(document.querySelector('.tw-selected')).backgroundColor")).to eq("rgb(234, 240, 246)")
    expect(page.evaluate_script("getComputedStyle(document.querySelector('.tw-panel')).boxShadow")).not_to eq("none")
    page.execute_script("document.documentElement.style.setProperty('--secondary', '#385e4e')")
    expect(page.evaluate_script("getComputedStyle(document.querySelector('.tw-selected')).backgroundColor")).to eq("rgb(234, 240, 246)")
    expect(page.evaluate_script("getComputedStyle(document.querySelector('.tw-action')).color")).to eq("rgb(56, 94, 78)")
  end

  it "displays the configured step deadline in the summary and overview" do
    deadline = 3.days.from_now.to_date
    create(:participatory_process_step, :active, participatory_process: space, end_date: deadline)
    visit routes.document_path(document, locale: :en)
    expect(page).to have_css(".tw-summary", text: I18n.l(deadline, locale: :en))
    expect(page).to have_css(".tw-deadline", text: I18n.l(deadline, locale: :en))
  end

  it "keeps the comment submit label readable when disabled and enabled" do
    open_paragraph
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

  it "does not flag an untouched comment on blur and keeps the required publication flow" do
    open_paragraph
    textarea = find(".tw-comments .new_comment textarea")
    2.times do
      textarea.click
      find("[data-panel-title]").click
      expect(page).to have_no_css(".tw-comments .is-invalid-input")
      expect(page).to have_no_css(".tw-comments .form-error.is-visible")
    end
    expect(page).to have_button("Publish comment", disabled: true)
    expect(textarea[:required]).to be_present
    expect(block.reload.comments_count).to eq(0)
    textarea.set("A valid comment.")
    expect(page).to have_no_css(".tw-comments .is-invalid-input")
    within(".tw-comments") { click_button "Publish comment" }
    expect(page).to have_content("A valid comment.")
    expect(block.reload.comments_count).to eq(1)
    find(".tw-comments .new_comment textarea").click
    find("[data-panel-title]").click
    expect(page).to have_no_css(".tw-comments .is-invalid-input")
  end

  it "renders flat comments and a compact form at desktop and mobile sizes" do
    comment = create(:comment, commentable: block, author: create(:user, :confirmed, organization:), body: { en: "Keep the drinking fountains accessible." })
    visit routes.document_path(document, locale: :en)
    open_paragraph
    [[1440, 900], [390, 844], [320, 700]].each do |width, height|
      page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width:, height:, deviceScaleFactor: 1, mobile: width < 1024)
      within ".tw-comments" do
        expect(page).to have_no_css(".comment__as")
        expect(page).to have_no_css(".author__avatar-container img")
        expect(page).to have_css(".tw-comment-initials", text: /\S+/)
        expect(page).to have_css("#comment_#{comment.id}", text: "Keep the drinking fountains accessible.")
        measurements = page.evaluate_script(<<~JS)
          (() => {
            const comment = document.querySelector('.tw-comments .comment');
            const form = document.querySelector('.tw-comments .new_comment');
            const textarea = form.querySelector('textarea');
            const body = comment.querySelector('.editor-content');
            const avatar = comment.querySelector('.author__avatar-container');
            return {
              border: getComputedStyle(comment).borderLeftWidth,
              avatar: avatar.getBoundingClientRect().width,
              body: parseFloat(getComputedStyle(body).fontSize),
              input: parseFloat(getComputedStyle(textarea).fontSize),
              inputHeight: textarea.getBoundingClientRect().height,
              padding: getComputedStyle(form.parentElement).paddingLeft,
              overflow: document.querySelector('.tw-panel-body').scrollWidth > document.querySelector('.tw-panel-body').clientWidth
            };
          })()
        JS
        expect(measurements.values_at("border", "padding", "overflow")).to eq(["0px", "0px", false])
        expect(measurements.values_at("body", "input")).to eq([18, 18])
        expect(measurements["avatar"]).to eq(26)
        expect(measurements["inputHeight"]).to be_between(74, 80)
      end
      find("#comment_#{comment.id}").scroll_to(:center)
      capture_screen("/private/tmp/textwork-comments-#{width}.png")
      expect_no_accessibility_violations
    end
  end

  it "keeps Core comment voting, replies, editing and deletion in the compact discussion" do
    comment = create(:comment, commentable: block, author: create(:user, :confirmed, organization:), body: { en: "Please include water." })
    visit routes.document_path(document, locale: :en)
    open_paragraph
    within "#comment_#{comment.id}" do
      find(".js-comment__votes--up").click
      expect(page).to have_css(".js-comment__votes--up.is-vote-selected", text: "1")
      find(".comment__actions button[data-controls]").click
      fill_in "Your reply", with: "Good point, especially in summer."
      click_button "Publish reply"
    end
    expect(page).to have_content("Good point, especially in summer.")
    reply = comment.replies.find_by!(author: user)
    within "#comment_#{reply.id}" do
      find("button[data-controller=dropdown]").click
      click_button "Edit", exact: true
    end
    within "#editCommentModal#{reply.id}" do
      find("textarea").set("Good point, especially during heatwaves.")
      click_button "Send", exact: true
    end
    expect(page).to have_content("Good point, especially during heatwaves.")
    within "#comment_#{reply.id}" do
      find("button[data-controller=dropdown]").click
      click_link "Delete", exact: true
    end
    within("#confirm-modal") { find("[data-confirm-ok]").click }
    expect(page).to have_no_content("Good point, especially during heatwaves.")
    expect(reply.reload).to be_deleted
    within "#comment_#{comment.id}" do
      find("button[data-controller=dropdown]").click
      find("[data-dialog-open='flagModalComment#{comment.id}']").click
    end
    expect(page).to have_css("#flagModalComment#{comment.id}[aria-hidden=false]")
  end

  it "keeps comment sorting usable in a narrow discussion" do
    comments = 5.times.map do |index|
      create(:comment, commentable: block, author: user, body: { en: "Comment #{index}" }, created_at: (5 - index).hours.ago)
    end
    visit routes.document_path(document, locale: :en)
    open_paragraph
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: 320, height: 700, deviceScaleFactor: 1, mobile: true)
    within ".tw-comments" do
      expect(page).to have_css(".comment-order-by")
      find("select", visible: true).select("Recent")
      expect(page).to have_css(".comment", count: 5)
      expect(first(".comment")[:id]).to eq("comment_#{comments.last.id}")
    end
    expect_no_accessibility_violations
  end

  it "separates editor fields and the comparison at desktop and mobile sizes" do
    open_paragraph
    click_button "Suggest a change", exact: true
    expect(page).to have_css("[data-suggestion-form]")
    [[1440, 900], [390, 844]].each do |width, height|
      page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width:, height:, deviceScaleFactor: 1, mobile: width == 390)
      measurements = page.evaluate_script(<<~JS)
        (() => {
          const form = document.querySelector('[data-suggestion-form]');
          const text = form.querySelector('#tw_body');
          const preview = form.querySelector('[data-live-diff]');
          const title = form.querySelector('.tw-editor-preview h4');
          const reason = form.querySelector('label[for=tw_justification]');
          const label = form.querySelector('label[for=tw_body]');
          const rect = element => element.getBoundingClientRect();
          const fontSize = element => parseFloat(getComputedStyle(element).fontSize);
          return {
            unit: parseFloat(getComputedStyle(document.documentElement).fontSize),
            label: rect(text).top - rect(label).bottom,
            sections: rect(title).top - rect(text).bottom,
            preview: rect(preview).top - rect(title).bottom,
            reason: rect(reason).top - rect(preview).bottom,
            textRows: text.rows,
            reasonRows: form.querySelector('#tw_justification').rows,
            bodyFont: fontSize(text),
            reasonFont: fontSize(form.querySelector('#tw_justification')),
            labelFont: fontSize(label),
            editorTitleFont: fontSize(document.querySelector('.tw-editor-title')),
            paragraphFont: fontSize(document.querySelector('.tw-copy')),
            chapterFont: fontSize(document.querySelector('.tw-heading h2')),
            documentTitleFont: fontSize(document.querySelector('.tw-intro h1')),
            panelTitleFont: fontSize(document.querySelector('.tw-panel-header h2')),
            paragraphLine: parseFloat(getComputedStyle(document.querySelector('.tw-copy')).lineHeight)
          };
        })()
      JS
      expect(measurements.values_at("label", "preview")).to all(be_within(1).of(measurements["unit"] * 0.375))
      expect(measurements.values_at("sections", "reason")).to all(be_within(1).of(measurements["unit"]))
      expect(measurements.values_at("textRows", "reasonRows")).to eq([4, 2])
      expect(measurements.values_at("bodyFont", "reasonFont", "editorTitleFont", "paragraphFont")).to eq([18, 18, 18, 18])
      expect(measurements.values_at("labelFont", "chapterFont", "documentTitleFont")).to eq(width == 390 ? [15, 22, 30] : [15, 24, 36])
      expect(measurements["panelTitleFont"]).to eq(width == 390 ? 22 : 24)
      expect(measurements["paragraphLine"]).to be_within(0.01).of(28)
      find_by_id("tw_body").set("More trees and shade!")
      expect(page).to have_css("[data-live-diff] ins", text: "!")
      expect(page.evaluate_script("parseFloat(getComputedStyle(document.querySelector('[data-live-diff]')).fontSize)")).to eq(18)
      page.execute_script("const body=document.querySelector('.tw-panel-body');body.scrollTop=body.scrollHeight;") if width == 1440
      capture_screen("/private/tmp/textwork-editor-spacing-#{width}.png")
      find_by_id("tw_body").set(block.original)
    end
  end

  it "keeps the original left, protects drafts and returns to the list after submission" do
    open_paragraph
    click_button "Suggest a change", exact: true
    expect(page).to have_css("[data-suggestion-form]")
    expect(page).to have_no_css(".tw-document textarea,.tw-document ins,.tw-document del")
    expect(page).to have_button("Submit suggestion", disabled: true)
    find_by_id("tw_body").set("More trees and shade!")
    expect(page).to have_css("[data-live-diff] ins", text: "!")
    page.driver.browser.action.send_keys(:escape).perform
    within ".tw-confirm" do
      expect(page).to have_content("Discard")
      expect(page).to have_css("[data-tw-choice=keep]:focus")
      find("[data-tw-choice=keep]").click
    end
    expect(page).to have_css("#tw_body:focus")
    find_by_id("tw_justification").set("An emphatic suggestion.")
    click_button "Submit suggestion"
    expect(page).to have_css("[data-panel-mode=list]")
    expect(page).to have_content("An emphatic suggestion.")
    expect(block.suggestions.last!.original).to eq("More trees and shade!")
    capture_screen("/private/tmp/textwork-desktop-list.png")
  end

  it "opens only three cards initially, shows all and withdraws an own suggestion" do
    propose(5)
    expect(page).to have_css(".tw-suggestion", count: 3)
    expect(page).to have_no_css(".tw-document [data-preview]")
    find(".tw-show-all").click
    expect(page).to have_css(".tw-suggestion", count: 5)
    within(all(".tw-suggestion").first) { click_button "Withdraw", exact: true }
    within(".tw-confirm") { find("[data-tw-choice=discard]").click }
    expect(page).to have_content("Your suggestion has been withdrawn.")
    expect(block.suggestions.where(status: "withdrawn").count).to eq(1)
  end

  it "shows the full comparison and Core comments in details, with one-level Escape" do
    propose
    within(".tw-suggestion") { find("[data-suggestion-id]:not([data-mode=edit])").click }
    expect(page).to have_css("[data-panel-mode=detail]")
    expect(page).to have_css(".tw-suggestion-detail [data-diff-output]")
    expect(page).to have_css(".tw-panel [data-decidim-comments]", count: 1)
    expect(page).to have_no_css(".tw-panel-actions")
    page.driver.browser.action.send_keys(:escape).perform
    expect(page).to have_css("[data-panel-mode=list]")
    page.driver.browser.action.send_keys(:escape).perform
    expect(page).to have_css("[data-overview]")
  end

  it "opens text on mobile, fits 390 and 320 pixels and traps keyboard focus" do
    [390, 320].each do |width|
      page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width:, height: 844, deviceScaleFactor: 1, mobile: true)
      expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
      find("#block-#{block.id} .tw-copy").click
      expect(page).to have_css('.tw-panel[aria-modal="true"][aria-label="Paragraph 1.1"]')
      expect(page).to have_css("[data-panel-title]:focus")
      expect(page.evaluate_script("[...document.querySelectorAll('body header, footer[role=contentinfo], .tw-intro, .tw-document')].filter(el => !el.closest('.tw-panel')).every(el => el.closest('[inert]'))")).to be(true)
      expect(page).to have_field("Your comment")
      expect(page).to have_css(".tw-mobile-quote", text: block.original)
      page.execute_script("const controls = [...document.querySelectorAll('.tw-panel button,.tw-panel a,.tw-panel textarea')].filter(el => !el.disabled && el.getClientRects().length); controls.at(-1).focus()")
      page.driver.browser.action.send_keys(:tab).perform
      expect(page.evaluate_script("document.querySelector('.tw-panel').contains(document.activeElement)")).to be(true)
      capture_screen("/private/tmp/textwork-mobile-#{width}.png")
      page.driver.browser.action.send_keys(:escape).perform
      expect(page).to have_no_css(".tw-panel")
      expect(page).to have_css("[data-block-pill='#{block.id}']:focus")
      expect(page.evaluate_script("document.querySelector('footer[role=contentinfo]').closest('[inert]') === null")).to be(true)
    end
  end

  it "restores the background and keeps reporting available inside the mobile sheet" do
    propose
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: 576, height: 844, deviceScaleFactor: 1, mobile: true)
    within(".tw-suggestion") { find("[data-suggestion-id]:not([data-mode=edit])").click }
    find("[data-dialog-open^=tw-report]").click
    expect(page).to have_css("[data-dialog^=tw-report][aria-hidden=false]")
    expect(page.evaluate_script("document.querySelector('[data-dialog^=tw-report][aria-hidden=false]').closest('[inert]') === null")).to be(true)
    expect(page.evaluate_script("document.querySelector('[data-dialog^=tw-report][aria-hidden=false]').contains(document.activeElement)")).to be(true)
    page.driver.browser.action.send_keys(:escape).perform
    expect(page).to have_css('.tw-panel[aria-modal="true"]')
    expect(page).to have_css("[data-panel-title]:focus")
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    expect(page).to have_no_css('.tw-panel[aria-modal="true"]')
    expect(page.evaluate_script("document.querySelector('footer[role=contentinfo]').closest('[inert]') === null")).to be(true)
  end

  it "keeps editor buttons inside the viewport and supports enlarged text spacing" do
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: true)
    open_paragraph
    click_button "Suggest a change", exact: true
    expect(page).to have_css("[data-suggestion-form]")
    expect(page.evaluate_script("document.querySelector('.tw-panel-footer').getBoundingClientRect().bottom <= innerHeight")).to be(true)
    find_by_id("tw_body").set("More trees and shade!")
    capture_screen("/private/tmp/textwork-mobile-editor.png")
    click_button "Submit suggestion"
    expect(page).to have_css("[data-panel-mode=list]")
    page.driver.browser.action.send_keys(:escape).perform
    expect(page).to have_no_css(".tw-panel")
    page.execute_script(<<~JS)
      const spacing = document.createElement('style');
      spacing.textContent = '.tw-page * { line-height: 1.5 !important; letter-spacing: .12em !important; word-spacing: .16em !important; } .tw-page p { margin-bottom: 2em !important; }';
      document.head.append(spacing);
      document.documentElement.style.fontSize = '200%';
    JS
    expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
    expect(page.evaluate_script("parseFloat(getComputedStyle(document.querySelector('.tw-copy')).fontSize)")).to eq(36)
    open_paragraph(second_block)
    expect(page).to have_button("Close", exact: true)
    expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
  end

  it "keeps the TOC overlay and reserves the right column at 1054 pixels without covering the footer" do
    page.driver.browser.manage.window.resize_to(1054, 700)
    left = page.evaluate_script("document.querySelector('.tw-copy').getBoundingClientRect().left")
    find(".tw-toc summary").click
    expect(page).to have_css(".tw-toc nav")
    expect(page.evaluate_script("document.querySelector('.tw-copy').getBoundingClientRect().left")).to eq(left)
    within(".tw-toc nav") { find("a[href='#block-#{heading.id}']").click }
    expect(page).to have_no_css(".tw-toc nav")
    open_paragraph
    expect(page.evaluate_script("[...document.querySelectorAll('[data-chapter-count]')].every(el => el.querySelector('.sr-only').textContent.includes('contributions'))")).to be(true)
    expect(page.evaluate_script("document.querySelector('.tw-panel').getBoundingClientRect().right <= innerWidth")).to be(true)
    page.execute_script("window.scrollTo(0, document.body.scrollHeight)")
    page.document.synchronize(errors: [Capybara::ExpectationNotMet]) do
      measurements = page.evaluate_script("(() => { const panel=document.querySelector('.tw-panel');const rail=document.querySelector('.tw-rail'); const footer=document.querySelector('footer[role=contentinfo]');return {bottom:panel.getBoundingClientRect().bottom, footer:footer.getBoundingClientRect().top, visibility:getComputedStyle(panel).visibility,height:panel.style.height,rail:rail.getBoundingClientRect().top}; })()")
      raise Capybara::ExpectationNotMet, measurements.inspect unless measurements["visibility"] == "hidden" || measurements["bottom"] <= measurements["footer"]
    end
    capture_screen("/private/tmp/textwork-desktop-1054.png")
  end

  it "dismisses contents outside the document, on focus leaving and with Escape without closing the paragraph" do
    summary = find(".tw-toc summary")
    summary.click
    expect(page).to have_css(".tw-toc[open]")
    find(".tw-intro h1").click
    expect(page).to have_no_css(".tw-toc[open]")
    summary.click
    find("footer[role=contentinfo]").scroll_to(:center)
    find("footer[role=contentinfo]").click
    expect(page).to have_no_css(".tw-toc[open]")
    summary.scroll_to(:center)
    summary.click
    open_paragraph(second_block)
    expect(page).to have_no_css(".tw-toc[open]")
    expect(page).to have_css("[data-panel-mode=list]")
    summary.click
    page.driver.browser.action.send_keys(:escape).perform
    expect(page).to have_no_css(".tw-toc[open]")
    expect(page).to have_css(".tw-toc summary:focus")
    expect(page).to have_css("[data-panel-mode=list]")
    summary.click
    page.execute_script("document.querySelector('.tw-panel [data-panel-title]').focus()")
    expect(page).to have_no_css(".tw-toc[open]")
    expect(page).to have_css("[data-panel-title]:focus")
  end

  it "keeps only the last requested paragraph when switching quickly" do
    3.times do
      find("[data-block-pill='#{block.id}']").click
      find("[data-block-pill='#{second_block.id}']").click
    end
    expect(page).to have_css("[data-panel-block='#{second_block.id}']")
    expect(page).to have_css(".tw-panel [data-decidim-comments]", count: 1)
  end

  it "passes automated WCAG checks in comments, cards, details and mobile editor" do
    propose
    expect_no_accessibility_violations
    within(".tw-suggestion") { find("[data-suggestion-id]:not([data-mode=edit])").click }
    expect(page).to have_css("[data-panel-mode=detail]")
    expect_no_accessibility_violations
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: true)
    expect_no_accessibility_violations
    click_button "Edit", exact: true
    expect(page).to have_css("[data-suggestion-form]")
    expect_no_accessibility_violations
  end

  it "displays four image formats at native ratio, never upscales, and fits mobile" do
    require "vips"
    document.unpublish!
    [[2400, 1000], [900, 1600], [900, 900], [120, 90]].each do |width, height|
      Tempfile.create(["textwork-#{width}x#{height}", ".png"]) do |file|
        Vips::Image.black(width, height, bands: 3).pngsave(file.path)
        image = Decidim::EditorImage.new(organization:, author: admin)
        image.file.attach(io: File.open(file.path), filename: "#{width}x#{height}.png", content_type: "image/png")
        image.save!
        editor.add(kind: "image", editor_image: image, image_alt: "Format #{width} by #{height}")
      end
    end
    document.publish!
    visit routes.document_path(document, locale: :en)
    expect(page).to have_css(".tw-image img", count: 4)
    [1440, 390].each do |width|
      page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width:, height: 900, deviceScaleFactor: 1, mobile: width == 390)
      page.execute_script("document.querySelectorAll('.tw-image img').forEach(image => image.loading = 'eager')")
      page.document.synchronize(errors: [Capybara::ExpectationNotMet]) do
        result = page.evaluate_script(<<~JS)
          [...document.querySelectorAll('.tw-image img')].every(image => {
            const rect = image.getBoundingClientRect();
            return image.complete && image.naturalWidth > 0 && rect.width <= image.naturalWidth + 1 && rect.height <= Math.min(480, innerHeight * .7) + 1 && Math.abs(rect.width / rect.height - image.naturalWidth / image.naturalHeight) < .01;
          })
        JS
        raise Capybara::ExpectationNotMet, "Images have not settled at their native ratio" unless result
      end
      expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
      expect(all(".tw-image").last).to have_no_button("Enlarge")
      capture_screen("/private/tmp/textwork-images-#{width}.png")
    end
  end

  it "fits imported image previews in the admin and renders German export and paragraph labels" do
    require "vips"
    document.unpublish!
    [[1600, 900], [900, 1600], [120, 90]].each do |width, height|
      Tempfile.create(["textwork-admin-#{width}", ".png"]) do |file|
        Vips::Image.black(width, height, bands: 3).pngsave(file.path)
        image = Decidim::EditorImage.new(organization:, author: admin)
        image.file.attach(io: File.open(file.path), filename: "#{width}x#{height}.png", content_type: "image/png")
        image.save!
        editor.add(kind: "image", editor_image: image, image_alt: "Format #{width} by #{height}")
      end
    end
    document.publish!
    login_as admin, scope: :user
    visit Decidim::EngineRouter.admin_proxy(component).textwork_path.sub(%r{\A/en/}, "/de/")
    expect(page).to have_button("Textarbeit exportieren")
    expect(page).to have_content("Absatz 1.1")
    expect(page).to have_no_content("%{number}")
    expect(page).to have_no_content("block_likes:")
    expect(page).to have_css("[data-textwork-admin-image] img", count: 3)
    page.document.synchronize(errors: [Capybara::ExpectationNotMet]) do
      sizes = page.evaluate_script(<<~JS)
        [...document.querySelectorAll('[data-textwork-admin-image] img')].map(image => {
          const rect = image.getBoundingClientRect();
          return {
            loaded: image.complete && image.naturalWidth > 0,
            ratio: rect.width / rect.height,
            naturalRatio: image.naturalWidth / image.naturalHeight,
            bounded: rect.height <= 15 * parseFloat(getComputedStyle(document.documentElement).fontSize) + 1 && rect.width <= image.parentElement.clientWidth + 1,
            width: rect.width
          };
        })
      JS
      expect(sizes.pluck("loaded", "bounded")).to all(eq([true, true]))
      sizes.each { |size| expect(size["ratio"]).to be_within(0.01).of(size["naturalRatio"]) }
      expect(sizes.last["width"]).to eq(120)
    end
    capture_screen("/private/tmp/textwork-admin-controls.png")
    page.execute_script("arguments[0].scrollIntoView({block: 'start'})", first("[data-textwork-admin-image]"))
    capture_screen("/private/tmp/textwork-admin-images.png")
  end

  it "fits a long document at two desktop sizes and keeps wheel scrolling inside the panel" do
    document.unpublish!
    20.times { editor.add(kind: "paragraph", body: "A paragraph about the neighbourhood. " * 12) }
    document.publish!
    propose(12)
    find(".tw-show-all").click
    expect(page).to have_css(".tw-suggestion", count: 12)
    [[1440, 900], [1054, 700]].each do |width, height|
      page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width:, height:, deviceScaleFactor: 1, mobile: false)
      page.document.synchronize(errors: [Capybara::ExpectationNotMet]) do
        gap = page.evaluate_script("innerHeight - document.querySelector('.tw-panel').getBoundingClientRect().bottom")
        raise Capybara::ExpectationNotMet, "Panel bottom gap is #{gap}" unless (gap - 16).abs < 1
      end
      page.execute_script("window.scrollTo(0, 500)")
      page.document.synchronize(errors: [Capybara::ExpectationNotMet]) do
        gap = page.evaluate_script("innerHeight - document.querySelector('.tw-panel').getBoundingClientRect().bottom")
        raise Capybara::ExpectationNotMet, "Sticky panel bottom gap is #{gap}" unless (gap - 16).abs < 1
      end
      page_top = page.evaluate_script("scrollY")
      coordinates = page.evaluate_script("(() => {const body=document.querySelector('.tw-panel-body');body.scrollTop=body.scrollHeight;const rect=body.getBoundingClientRect();return {x:rect.left+rect.width/2,y:rect.top+rect.height/2};})()")
      page.driver.browser.execute_cdp("Input.dispatchMouseEvent", type: "mouseWheel", x: coordinates["x"], y: coordinates["y"], deltaX: 0, deltaY: 600)
      page.document.synchronize(errors: [Capybara::ExpectationNotMet]) do
        raise Capybara::ExpectationNotMet, "The document scrolled through the panel" unless page.evaluate_script("scrollY") == page_top
      end
      capture_screen("/private/tmp/textwork-long-#{width}.png")
    end
  end

  # Screenshots are evidence for the manual layout inspection, not a debugger.
  it "supports the whole keyboard flow and returns focus after discarding an editor draft" do
    find("[data-block-pill='#{block.id}']").send_keys(:enter)
    expect(page).to have_css("[data-panel-mode=list]")
    find(".tw-panel [data-kind=like]").send_keys(:enter)
    expect(page).to have_css("[data-interaction-label]", text: "Agreed")
    find_button("Suggest a change", exact: true).send_keys(:enter)
    find_by_id("tw_body").send_keys(:end, " Schools first.")
    find_button("Submit suggestion").send_keys(:enter)
    expect(page).to have_css("[data-panel-mode=list]")
    find_button("Suggest a change", exact: true).send_keys(:enter)
    find_by_id("tw_body").send_keys(:end, " Unsaved.")
    page.driver.browser.action.send_keys(:escape).perform
    expect(page).to have_css(".tw-confirm[open]")
    find("[data-tw-choice=discard]").send_keys(:enter)
    expect(page).to have_css("[data-panel-mode=list]")
    page.driver.browser.action.send_keys(:escape).perform
    expect(page).to have_css("[data-block-pill='#{block.id}']:focus")
  end

  it "keeps closed participation readable while hiding all writing actions" do
    propose
    component.update!(default_step_settings: { comments_blocked: true, likes_blocked: true, suggestions_blocked: true })
    visit routes.document_path(document, locale: :en)
    expect(page).to have_no_css("[data-help]")
    open_paragraph
    expect(page).to have_css(".tw-suggestion")
    expect(page).to have_no_button("Suggest a change", exact: true)
    expect(page).to have_no_css("[data-kind=like],[data-suggestion-form],textarea:not([disabled])")
    expect(page).to have_no_button("Edit", exact: true)
    expect(page).to have_no_button("Withdraw", exact: true)
    within(".tw-suggestion") { find("[data-suggestion-id]:not([data-mode=edit])").click }
    expect(page).to have_css("[data-panel-mode=detail]")
    expect(page).to have_css("[data-dialog-open^=tw-report]")
    find("[data-dialog-open^=tw-report]").click
    expect(page).to have_css("[data-dialog^=tw-report][aria-hidden=false]")
  end

  it "enlarges the original uploaded image on mobile without horizontal scrolling" do
    document.unpublish!
    image = create(:editor_image, organization:, author: admin)
    editor.add(kind: "image", editor_image: image, image_alt: "Trees")
    document.publish!
    visit routes.document_path(document, locale: :en)
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: true)
    expect(page).to have_css(".tw-image img[alt=Trees]")
    expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
    within(".tw-image") { click_button "Enlarge", exact: true }
    expect(page).to have_css(".tw-image-dialog[open] img[alt=Trees]")
    expect(page.evaluate_script("document.querySelector('.tw-image-dialog img').src")).to include("/blobs/")
    expect_no_accessibility_violations
    page.driver.browser.action.send_keys(:escape).perform
    expect(page).to have_no_css(".tw-image-dialog[open]")
    expect(page).to have_css(".tw-image button:focus")
  end

  def capture_screen(path)
    page.save_screenshot(path) # rubocop:disable Lint/Debugger
  end

  def expect_no_accessibility_violations
    page.execute_script(File.read(File.expand_path("../../node_modules/axe-core/axe.min.js", __dir__)))
    violations = page.driver.browser.execute_async_script(<<~JS)
      const done = arguments[0];
      axe.run(document.querySelector('.tw-page'), {runOnly: {type:'tag', values:['wcag2a','wcag2aa','wcag21aa','wcag22aa','best-practice']}})
        .then(result => done(result.violations.map(issue => ({id:issue.id, targets:issue.nodes.map(node => node.target)}))));
    JS
    expect(violations).to eq([])
  end

  # Disabled controls are skipped by axe's contrast rule. Measure the visible
  # label separately, compositing alpha/opacity against its rendered background.
  def expect_readable_comment_submit
    page.execute_script("arguments[0].scrollIntoView({block: 'center'})", find('.comment__form-submit button[type="submit"]'))
    # Core animates color changes; assert the settled state without a fixed sleep.
    page.document.synchronize(errors: [Capybara::ExpectationNotMet]) do
      contrast = comment_submit_contrast
      raise Capybara::ExpectationNotMet, "Expected comment label contrast >= 4.5, got #{contrast}" if contrast < 4.5
    end
    expect(page.evaluate_script(<<~JS)).to be(true)
      (() => {
        const button = document.querySelector('.tw-panel .comment__form-submit button[type="submit"]');
        return getComputedStyle(button.querySelector('svg')).fill === getComputedStyle(button).color;
      })()
    JS
  end

  def comment_submit_contrast
    page.evaluate_script(<<~JS)
      (() => {
        const button = document.querySelector('.tw-panel .comment__form-submit button[type="submit"]');
        const label = button.querySelector('span');
        // Resolve CSS Color 4 values (including color-mix) to sRGB bytes.
        const canvas = document.createElement('canvas');
        canvas.width = canvas.height = 1;
        const context = canvas.getContext('2d', { willReadFrequently: true });
        const color = value => {
          context.clearRect(0, 0, 1, 1);
          context.fillStyle = value;
          context.fillRect(0, 0, 1, 1);
          const [red, green, blue, alpha] = context.getImageData(0, 0, 1, 1).data;
          return [red, green, blue, alpha / 255];
        };
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
