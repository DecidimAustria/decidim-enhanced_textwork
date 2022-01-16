# frozen_string_literal: true

require "spec_helper"

describe "Admin views paragraph details from admin", type: :system do
  include_context "when admin manages paragraphs"
  include ActionView::Helpers::TextHelper

  let(:address) { "Some address" }
  let(:latitude) { 40.1234 }
  let(:longitude) { 2.1234 }
  let(:participatory_process) { create(:participatory_process, :with_steps, organization: organization, scope: participatory_process_scope) }
  let(:participatory_process_scope) { nil }

  before do
    stub_geocoding(address, [latitude, longitude])
  end

  it "has a link to the paragraph" do
    go_to_admin_paragraph_page(paragraph)
    path = "processes/#{participatory_process.slug}/f/#{component.id}/paragraphs/#{paragraph.id}"

    expect(page).to have_selector("a", text: path)
  end

  describe "with authors" do
    it "has a link to each author profile" do
      go_to_admin_paragraph_page(paragraph)

      within "#paragraph-authors-list" do
        paragraph.authors.each do |author|
          list_item = find("li", text: author.name)

          within list_item do
            expect(page).to have_selector("a", text: author.name)
            expect(page).to have_selector(:xpath, './/a[@title="Contact"]')
          end
        end
      end
    end

    context "when it has an organization as an author" do
      let!(:paragraph) { create :paragraph, :official, component: current_component }

      it "doesn't show a link to the organization" do
        go_to_admin_paragraph_page(paragraph)

        within "#paragraph-authors-list" do
          expect(page).to have_no_selector("a", text: "Official paragraph")
          expect(page).to have_content("Official paragraph")
        end
      end
    end
  end

  it "shows the paragraph body" do
    go_to_admin_paragraph_page(paragraph)

    expect(page).to have_content(strip_tags(translated(paragraph.body)).strip)
  end

  describe "with an specific creation date" do
    let!(:paragraph) { create :paragraph, component: current_component, created_at: Time.zone.parse("2020-01-29 15:00") }

    it "shows the paragraph creation date" do
      go_to_admin_paragraph_page(paragraph)

      expect(page).to have_content("Creation date: 29/01/2020 15:00")
    end
  end

  describe "with supports" do
    before do
      create_list :paragraph_vote, 2, paragraph: paragraph
    end

    it "shows the number of supports" do
      go_to_admin_paragraph_page(paragraph)

      expect(page).to have_content("Supports count: 2")
    end

    it "shows the ranking by supports" do
      another_paragraph = create :paragraph, component: component
      create :paragraph_vote, paragraph: another_paragraph
      go_to_admin_paragraph_page(paragraph)

      expect(page).to have_content("Ranking by supports: 1 of")
    end
  end

  describe "with endorsements" do
    let!(:endorsements) do
      2.times.collect do
        create(:endorsement, resource: paragraph, author: build(:user, organization: organization))
      end
    end

    it "shows the number of endorsements" do
      go_to_admin_paragraph_page(paragraph)

      expect(page).to have_content("Endorsements count: 2")
    end

    it "shows the ranking by endorsements" do
      another_paragraph = create :paragraph, component: component
      create(:endorsement, resource: another_paragraph, author: build(:user, organization: organization))
      go_to_admin_paragraph_page(paragraph)

      expect(page).to have_content("Ranking by endorsements: 1 of")
    end

    it "has a link to each endorser profile" do
      go_to_admin_paragraph_page(paragraph)

      within "#paragraph-endorsers-list" do
        paragraph.endorsements.for_listing.each do |endorsement|
          endorser = endorsement.normalized_author
          expect(page).to have_selector("a", text: endorser.name)
        end
      end
    end

    context "with more than 5 endorsements" do
      let!(:endorsements) do
        6.times.collect do
          create(:endorsement, resource: paragraph, author: build(:user, organization: organization))
        end
      end

      it "links to the paragraph page to check the rest of endorsements" do
        go_to_admin_paragraph_page(paragraph)

        within "#paragraph-endorsers-list" do
          expect(page).to have_selector("a", text: "and 1 more")
        end
      end
    end
  end

  it "shows the number of amendments" do
    create :paragraph_amendment, amendable: paragraph
    go_to_admin_paragraph_page(paragraph)

    expect(page).to have_content("Amendments count: 1")
  end

  describe "with comments" do
    before do
      create_list :comment, 2, commentable: paragraph, alignment: -1
      create_list :comment, 3, commentable: paragraph, alignment: 1
      create :comment, commentable: paragraph, alignment: 0

      go_to_admin_paragraph_page(paragraph)
    end

    it "shows the number of comments" do
      expect(page).to have_content("Comments count: 6")
    end

    it "groups the number of comments by alignment" do
      within "#paragraph-comments-alignment-count" do
        expect(page).to have_content("Favor: 3")
        expect(page).to have_content("Neutral: 1")
        expect(page).to have_content("Against: 2")
      end
    end
  end

  context "with related meetings" do
    let(:meeting_component) { create :meeting_component, participatory_space: participatory_process }
    let(:meeting) { create :meeting, component: meeting_component }

    it "lists the related meetings" do
      paragraph.link_resources(meeting, "paragraphs_from_meeting")
      go_to_admin_paragraph_page(paragraph)

      within "#related-meetings" do
        expect(page).to have_selector("a", text: translated(meeting.title))
      end
    end
  end

  context "with attached documents" do
    it "lists the documents" do
      document = create :attachment, :with_pdf, attached_to: paragraph
      go_to_admin_paragraph_page(paragraph)

      within "#documents" do
        expect(page).to have_selector("a", text: translated(document.title))
        expect(page).to have_content(document.file_type)
      end
    end
  end

  context "with attached photos" do
    it "lists the documents" do
      image = create :attachment, :with_image, attached_to: paragraph
      go_to_admin_paragraph_page(paragraph)

      within "#photos" do
        expect(page).to have_selector(:xpath, "//img[@src=\"#{image.thumbnail_url}\"]")
        expect(page).to have_selector(:xpath, "//a[@href=\"#{image.big_url}\"]")
      end
    end
  end

  def go_to_admin_paragraph_page(paragraph)
    within find("tr", text: translated(paragraph.title)) do
      find("a", class: "action-icon--show-paragraph").click
    end
  end
end
