# frozen_string_literal: true

shared_examples "merge paragraphs" do
  let!(:paragraphs) { create_list :paragraph, 3, :official, component: current_component }
  let!(:target_component) { create :paragraph_component, participatory_space: current_component.participatory_space }
  include Decidim::ComponentPathHelper

  before do
    Decidim::EnhancedTextwork::Paragraph.where.not(id: paragraphs.map(&:id)).destroy_all
  end

  context "when selecting paragraphs" do
    before do
      visit current_path
      page.find("#paragraphs_bulk.js-check-all").set(true)
    end

    context "when click the bulk action button" do
      it "shows the change action option" do
        click_button "Actions"

        expect(page).to have_selector(:link_or_button, "Merge into a new one")
      end

      context "when only one paragraph is checked" do
        before do
          page.find("#paragraphs_bulk.js-check-all").set(false)
          page.first(".js-paragraph-list-check").set(true)
        end

        it "does not show the merge action option" do
          click_button "Actions"

          expect(page).to have_no_selector(:link_or_button, "Merge into a new one")
        end
      end
    end

    context "when merge into a new one is selected from the actions dropdown" do
      before do
        click_button "Actions"
        click_button "Merge into a new one"
      end

      it "shows the component select" do
        expect(page).to have_css("#js-form-merge-paragraphs select", count: 1)
      end

      it "shows an update button" do
        expect(page).to have_css("button#js-submit-merge-paragraphs", count: 1)
      end

      context "when submiting the form" do
        before do
          within "#js-form-merge-paragraphs" do
            select translated(target_component.name), from: :target_component_id_
            page.find("button#js-submit-merge-paragraphs").click
          end
        end

        it "creates a new paragraph" do
          expect(page).to have_content("Successfully merged the paragraphs into a new one")
          expect(page).to have_css(".table-list tbody tr", count: 1)
          expect(page).to have_current_path(manage_component_path(target_component))
        end

        context "when merging to the same component" do
          let!(:target_component) { current_component }
          let!(:paragraph_ids) { paragraphs.map(&:id) }

          context "when the paragraphs can't be merged" do
            let!(:paragraphs) { create_list :paragraph, 3, :with_endorsements, :with_votes, component: current_component }

            it "doesn't create a new paragraph and displays a validation fail message" do
              expect(page).to have_css(".table-list tbody tr", count: 3)
              expect(page).to have_content("There has been a problem merging the selected paragraphs")
              expect(page).to have_content("Are not official")
              expect(page).to have_content("Have received support or endorsements")
            end
          end

          it "creates a new paragraph and deletes the other ones" do
            expect(page).to have_content("Successfully merged the paragraphs into a new one")
            expect(page).to have_css(".table-list tbody tr", count: 1)
            expect(page).to have_current_path(manage_component_path(current_component))

            paragraph_ids.each do |id|
              expect(page).not_to have_xpath("//tr[@data-id='#{id}']")
            end
          end
        end
      end
    end
  end
end
