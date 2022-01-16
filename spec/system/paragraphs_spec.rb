# frozen_string_literal: true

require "spec_helper"

describe "Paragraphs", type: :system do
  include ActionView::Helpers::TextHelper
  include_context "with a component"
  let(:manifest_name) { "paragraphs" }

  let!(:category) { create :category, participatory_space: participatory_process }
  let!(:scope) { create :scope, organization: organization }
  let!(:user) { create :user, :confirmed, organization: organization }
  let(:scoped_participatory_process) { create(:participatory_process, :with_steps, organization: organization, scope: scope) }

  let(:address) { "Some address" }
  let(:latitude) { 40.1234 }
  let(:longitude) { 2.1234 }

  let(:paragraph_title) { translated(paragraph.title) }

  before do
    stub_geocoding(address, [latitude, longitude])
  end

  matcher :have_author do |name|
    match { |node| node.has_selector?(".author-data", text: name) }
    match_when_negated { |node| node.has_no_selector?(".author-data", text: name) }
  end

  matcher :have_creation_date do |date|
    match { |node| node.has_selector?(".author-data__extra", text: date) }
    match_when_negated { |node| node.has_no_selector?(".author-data__extra", text: date) }
  end

  context "when viewing a single paragraph" do
    let!(:component) do
      create(:paragraph_component,
             manifest: manifest,
             participatory_space: participatory_process,
             settings: {
               scopes_enabled: true,
               scope_id: participatory_process.scope&.id
             })
    end

    let!(:paragraphs) { create_list(:paragraph, 3, component: component) }
    let!(:paragraph) { paragraphs.first }

    it_behaves_like "accessible page" do
      before do
        visit_component
        click_link paragraph_title
      end
    end

    it "allows viewing a single paragraph" do
      visit_component

      click_link paragraph_title

      expect(page).to have_content(paragraph_title)
      expect(page).to have_content(strip_tags(translated(paragraph.body)).strip)
      expect(page).to have_author(paragraph.creator_author.name)
      expect(page).to have_content(paragraph.reference)
      expect(page).to have_creation_date(I18n.l(paragraph.published_at, format: :decidim_short))
    end

    context "when process is not related to any scope" do
      let!(:paragraph) { create(:paragraph, component: component, scope: scope) }

      it "can be filtered by scope" do
        visit_component
        click_link paragraph_title
        expect(page).to have_content(translated(scope.name))
      end
    end

    context "when process is related to a child scope" do
      let!(:paragraph) { create(:paragraph, component: component, scope: scope) }
      let(:participatory_process) { scoped_participatory_process }

      it "does not show the scope name" do
        visit_component
        click_link paragraph_title
        expect(page).to have_no_content(translated(scope.name))
      end
    end

    context "when it is an official paragraph" do
      let(:content) { generate_localized_title }
      let!(:official_paragraph) { create(:paragraph, :official, body: content, component: component) }
      let!(:official_paragraph_title) { translated(official_paragraph.title) }

      before do
        visit_component
        click_link official_paragraph_title
      end

      it "shows the author as official" do
        expect(page).to have_content("Official paragraph")
      end

      it_behaves_like "rendering safe content", ".columns.mediumlarge-8.large-9"
    end

    context "when rich text editor is enabled for participants" do
      let!(:paragraph) { create(:paragraph, body: content, component: component) }

      before do
        organization.update(rich_text_editor_in_public_views: true)
        visit_component
        click_link paragraph_title
      end

      it_behaves_like "rendering safe content", ".columns.mediumlarge-8.large-9"
    end

    context "when rich text editor is NOT enabled for participants" do
      let!(:paragraph) { create(:paragraph, body: content, component: component) }

      before do
        visit_component
        click_link paragraph_title
      end

      it_behaves_like "rendering unsafe content", ".columns.mediumlarge-8.large-9"
    end

    context "when it is a paragraph with image" do
      let!(:component) do
        create(:paragraph_component,
               manifest: manifest,
               participatory_space: participatory_process)
      end

      let!(:paragraph) { create(:paragraph, component: component) }
      let!(:image) { create(:attachment, attached_to: paragraph) }

      it "shows the card image" do
        visit_component
        within "#paragraph_#{paragraph.id}" do
          expect(page).to have_selector(".card__image")
        end
      end
    end

    context "when it is an official meeting paragraph" do
      include_context "with rich text editor content"
      let!(:paragraph) { create(:paragraph, :official_meeting, body: content, component: component) }

      before do
        visit_component
        click_link paragraph_title
      end

      it "shows the author as meeting" do
        expect(page).to have_content(translated(paragraph.authors.first.title))
      end

      it_behaves_like "rendering safe content", ".columns.mediumlarge-8.large-9"
    end

    context "when a paragraph has comments" do
      let(:paragraph) { create(:paragraph, component: component) }
      let(:author) { create(:user, :confirmed, organization: component.organization) }
      let!(:comments) { create_list(:comment, 3, commentable: paragraph) }

      it "shows the comments" do
        visit_component
        click_link paragraph_title

        comments.each do |comment|
          expect(page).to have_content(comment.body.values.first)
        end
      end
    end

    context "when a paragraph has costs" do
      let!(:paragraph) do
        create(
          :paragraph,
          :accepted,
          :with_answer,
          component: component,
          cost: 20_000,
          cost_report: { en: "My cost report" },
          execution_period: { en: "My execution period" }
        )
      end
      let!(:author) { create(:user, :confirmed, organization: component.organization) }

      it "shows the costs" do
        component.update!(
          step_settings: {
            component.participatory_space.active_step.id => {
              answers_with_costs: true
            }
          }
        )

        visit_component
        click_link paragraph_title

        expect(page).to have_content("20,000.00")
        expect(page).to have_content("MY EXECUTION PERIOD")
        expect(page).to have_content("My cost report")
      end
    end

    context "when a paragraph has been linked in a meeting" do
      let(:paragraph) { create(:paragraph, component: component) }
      let(:meeting_component) do
        create(:component, manifest_name: :meetings, participatory_space: paragraph.component.participatory_space)
      end
      let(:meeting) { create(:meeting, component: meeting_component) }

      before do
        meeting.link_resources([paragraph], "paragraphs_from_meeting")
      end

      it "shows related meetings" do
        visit_component
        click_link paragraph_title

        expect(page).to have_i18n_content(meeting.title)
      end
    end

    context "when a paragraph has been linked in a result" do
      let(:paragraph) { create(:paragraph, component: component) }
      let(:accountability_component) do
        create(:component, manifest_name: :accountability, participatory_space: paragraph.component.participatory_space)
      end
      let(:result) { create(:result, component: accountability_component) }

      before do
        result.link_resources([paragraph], "included_paragraphs")
      end

      it "shows related resources" do
        visit_component
        click_link paragraph_title

        expect(page).to have_i18n_content(result.title)
      end
    end

    context "when a paragraph is in evaluation" do
      let!(:paragraph) { create(:paragraph, :with_answer, :evaluating, component: component) }

      it "shows a badge and an answer" do
        visit_component
        click_link paragraph_title

        expect(page).to have_content("Evaluating")

        within ".callout.warning" do
          expect(page).to have_content("This paragraph is being evaluated")
          expect(page).to have_i18n_content(paragraph.answer)
        end
      end
    end

    context "when a paragraph has been rejected" do
      let!(:paragraph) { create(:paragraph, :with_answer, :rejected, component: component) }

      it "shows the rejection reason" do
        visit_component
        uncheck "Accepted"
        uncheck "Evaluating"
        uncheck "Not answered"
        page.find_link(paragraph_title, wait: 30)
        click_link paragraph_title

        expect(page).to have_content("Rejected")

        within ".callout.alert" do
          expect(page).to have_content("This paragraph has been rejected")
          expect(page).to have_i18n_content(paragraph.answer)
        end
      end
    end

    context "when a paragraph has been accepted" do
      let!(:paragraph) { create(:paragraph, :with_answer, :accepted, component: component) }

      it "shows the acceptance reason" do
        visit_component
        click_link paragraph_title

        expect(page).to have_content("Accepted")

        within ".callout.success" do
          expect(page).to have_content("This paragraph has been accepted")
          expect(page).to have_i18n_content(paragraph.answer)
        end
      end
    end

    context "when the paragraph answer has not been published" do
      let!(:paragraph) { create(:paragraph, :accepted_not_published, component: component) }

      it "shows the acceptance reason" do
        visit_component
        click_link paragraph_title

        expect(page).not_to have_content("Accepted")
        expect(page).not_to have_content("This paragraph has been accepted")
        expect(page).not_to have_i18n_content(paragraph.answer)
      end
    end

    context "when the paragraphs'a author account has been deleted" do
      let(:paragraph) { paragraphs.first }

      before do
        Decidim::DestroyAccount.call(paragraph.creator_author, Decidim::DeleteAccountForm.from_params({}))
      end

      it "the user is displayed as a deleted user" do
        visit_component

        click_link paragraph_title

        expect(page).to have_content("Participant deleted")
      end
    end
  end

  context "when a paragraph has been linked in a project" do
    let(:component) do
      create(:paragraph_component,
             manifest: manifest,
             participatory_space: participatory_process)
    end
    let(:paragraph) { create(:paragraph, component: component) }
    let(:budget_component) do
      create(:component, manifest_name: :budgets, participatory_space: paragraph.component.participatory_space)
    end
    let(:project) { create(:project, component: budget_component) }

    before do
      project.link_resources([paragraph], "included_paragraphs")
    end

    it "shows related projects" do
      visit_component
      click_link paragraph_title

      expect(page).to have_i18n_content(project.title)
    end
  end

  context "when listing paragraphs in a participatory process" do
    shared_examples_for "a random paragraph ordering" do
      let!(:lucky_paragraph) { create(:paragraph, component: component) }
      let!(:unlucky_paragraph) { create(:paragraph, component: component) }
      let!(:lucky_paragraph_title) { translated(lucky_paragraph.title) }
      let!(:unlucky_paragraph_title) { translated(unlucky_paragraph.title) }

      it "lists the paragraphs ordered randomly by default" do
        visit_component

        expect(page).to have_selector("a", text: "Random")
        expect(page).to have_selector(".card--paragraph", count: 2)
        expect(page).to have_selector(".card--paragraph", text: lucky_paragraph_title)
        expect(page).to have_selector(".card--paragraph", text: unlucky_paragraph_title)
        expect(page).to have_author(lucky_paragraph.creator_author.name)
      end
    end

    it_behaves_like "accessible page" do
      before { visit_component }
    end

    it "lists all the paragraphs" do
      create(:paragraph_component,
             manifest: manifest,
             participatory_space: participatory_process)

      create_list(:paragraph, 3, component: component)

      visit_component
      expect(page).to have_css(".card--paragraph", count: 3)
    end

    describe "editable content" do
      it_behaves_like "editable content for admins" do
        let(:target_path) { main_component_path(component) }
      end
    end

    context "when comments have been moderated" do
      let(:paragraph) { create(:paragraph, component: component) }
      let(:author) { create(:user, :confirmed, organization: component.organization) }
      let!(:comments) { create_list(:comment, 3, commentable: paragraph) }
      let!(:moderation) { create :moderation, reportable: comments.first, hidden_at: 1.day.ago }

      it "displays unhidden comments count" do
        visit_component

        within("#paragraph_#{paragraph.id}") do
          within(".card-data__item:last-child") do
            expect(page).to have_content(2)
          end
        end
      end
    end

    describe "default ordering" do
      it_behaves_like "a random paragraph ordering"
    end

    context "when voting phase is over" do
      let!(:component) do
        create(:paragraph_component,
               :with_votes_blocked,
               manifest: manifest,
               participatory_space: participatory_process)
      end

      let!(:most_voted_paragraph) do
        paragraph = create(:paragraph, component: component)
        create_list(:paragraph_vote, 3, paragraph: paragraph)
        paragraph
      end
      let!(:most_voted_paragraph_title) { translated(most_voted_paragraph.title) }

      let!(:less_voted_paragraph) { create(:paragraph, component: component) }
      let!(:less_voted_paragraph_title) { translated(less_voted_paragraph.title) }

      before { visit_component }

      it "lists the paragraphs ordered by votes by default" do
        expect(page).to have_selector("a", text: "Most supported")
        expect(page).to have_selector("#paragraphs .card-grid .column:first-child", text: most_voted_paragraph_title)
        expect(page).to have_selector("#paragraphs .card-grid .column:last-child", text: less_voted_paragraph_title)
      end

      it "shows a disabled vote button for each paragraph, but no links to full paragraphs" do
        expect(page).to have_button("Supports disabled", disabled: true, count: 2)
        expect(page).to have_no_link("View paragraph")
      end
    end

    context "when voting is disabled" do
      let!(:component) do
        create(:paragraph_component,
               :with_votes_disabled,
               manifest: manifest,
               participatory_space: participatory_process)
      end

      describe "order" do
        it_behaves_like "a random paragraph ordering"
      end

      it "shows only links to full paragraphs" do
        create_list(:paragraph, 2, component: component)

        visit_component

        expect(page).to have_no_button("Supports disabled", disabled: true)
        expect(page).to have_no_button("Vote")
        expect(page).to have_link("View paragraph", count: 2)
      end
    end

    context "when there are a lot of paragraphs" do
      before do
        create_list(:paragraph, Decidim::Paginable::OPTIONS.first + 5, component: component)
      end

      it "paginates them" do
        visit_component

        expect(page).to have_css(".card--paragraph", count: Decidim::Paginable::OPTIONS.first)

        click_link "Next"

        expect(page).to have_selector(".pagination .current", text: "2")

        expect(page).to have_css(".card--paragraph", count: 5)
      end
    end

    shared_examples "ordering paragraphs by selected option" do |selected_option|
      let(:first_paragraph_title) { translated(first_paragraph.title) }
      let(:last_paragraph_title) { translated(last_paragraph.title) }
      before do
        visit_component
        within ".order-by" do
          expect(page).to have_selector("ul[data-dropdown-menu$=dropdown-menu]", text: "Random")
          page.find("a", text: "Random").click
          click_link(selected_option)
        end
      end

      it "lists the paragraphs ordered by selected option" do
        expect(page).to have_selector("#paragraphs .card-grid .column:first-child", text: first_paragraph_title)
        expect(page).to have_selector("#paragraphs .card-grid .column:last-child", text: last_paragraph_title)
      end
    end

    context "when ordering by 'most_voted'" do
      let!(:component) do
        create(:paragraph_component,
               :with_votes_enabled,
               manifest: manifest,
               participatory_space: participatory_process)
      end
      let!(:most_voted_paragraph) { create(:paragraph, component: component) }
      let!(:votes) { create_list(:paragraph_vote, 3, paragraph: most_voted_paragraph) }
      let!(:less_voted_paragraph) { create(:paragraph, component: component) }

      it_behaves_like "ordering paragraphs by selected option", "Most supported" do
        let(:first_paragraph) { most_voted_paragraph }
        let(:last_paragraph) { less_voted_paragraph }
      end
    end

    context "when ordering by 'recent'" do
      let!(:older_paragraph) { create(:paragraph, component: component, created_at: 1.month.ago) }
      let!(:recent_paragraph) { create(:paragraph, component: component) }

      it_behaves_like "ordering paragraphs by selected option", "Recent" do
        let(:first_paragraph) { recent_paragraph }
        let(:last_paragraph) { older_paragraph }
      end
    end

    context "when ordering by 'most_followed'" do
      let!(:most_followed_paragraph) { create(:paragraph, component: component) }
      let!(:follows) { create_list(:follow, 3, followable: most_followed_paragraph) }
      let!(:less_followed_paragraph) { create(:paragraph, component: component) }

      it_behaves_like "ordering paragraphs by selected option", "Most followed" do
        let(:first_paragraph) { most_followed_paragraph }
        let(:last_paragraph) { less_followed_paragraph }
      end
    end

    context "when ordering by 'most_commented'" do
      let!(:most_commented_paragraph) { create(:paragraph, component: component, created_at: 1.month.ago) }
      let!(:comments) { create_list(:comment, 3, commentable: most_commented_paragraph) }
      let!(:less_commented_paragraph) { create(:paragraph, component: component) }

      it_behaves_like "ordering paragraphs by selected option", "Most commented" do
        let(:first_paragraph) { most_commented_paragraph }
        let(:last_paragraph) { less_commented_paragraph }
      end
    end

    context "when ordering by 'most_endorsed'" do
      let!(:most_endorsed_paragraph) { create(:paragraph, component: component, created_at: 1.month.ago) }
      let!(:endorsements) do
        3.times.collect do
          create(:endorsement, resource: most_endorsed_paragraph, author: build(:user, organization: organization))
        end
      end
      let!(:less_endorsed_paragraph) { create(:paragraph, component: component) }

      it_behaves_like "ordering paragraphs by selected option", "Most endorsed" do
        let(:first_paragraph) { most_endorsed_paragraph }
        let(:last_paragraph) { less_endorsed_paragraph }
      end
    end

    context "when ordering by 'with_more_authors'" do
      let!(:most_authored_paragraph) { create(:paragraph, component: component, created_at: 1.month.ago) }
      let!(:coauthorships) { create_list(:coauthorship, 3, coauthorable: most_authored_paragraph) }
      let!(:less_authored_paragraph) { create(:paragraph, component: component) }

      it_behaves_like "ordering paragraphs by selected option", "With more authors" do
        let(:first_paragraph) { most_authored_paragraph }
        let(:last_paragraph) { less_authored_paragraph }
      end
    end

    context "when searching paragraphs" do
      let!(:paragraphs) do
        [
          create(:paragraph, title: "Lorem ipsum dolor sit amet", component: component),
          create(:paragraph, title: "Donec vitae convallis augue", component: component),
          create(:paragraph, title: "Pellentesque habitant morbi", component: component)
        ]
      end

      before do
        visit_component
      end

      it "finds the correct paragraph" do
        within "form.new_filter" do
          find("input[name='filter[search_text]']", match: :first).set("lorem")
          find("*[type=submit]").click
        end

        expect(page).to have_content("Lorem ipsum dolor sit amet")
      end
    end

    context "when paginating" do
      let!(:collection) { create_list :paragraph, collection_size, component: component }
      let!(:resource_selector) { ".card--paragraph" }

      it_behaves_like "a paginated resource"
    end

    context "when component is not commentable" do
      let!(:resources) { create_list(:paragraph, 3, component: component) }

      it_behaves_like "an uncommentable component"
    end
  end
end
