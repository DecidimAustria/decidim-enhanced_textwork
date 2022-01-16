# frozen_string_literal: true

require "spec_helper"

describe "Amendment Diff", versioning: true, type: :system do
  let!(:component) { create(:paragraph_component) }
  let!(:paragraph) { create(:paragraph, title: { en: "Original long enough title" }, body: { en: "Original one liner body" }, component: component) }
  # The first version of the emendation should hold the original paragraph attribute values being amended.
  let!(:emendation) { create(:paragraph, title: paragraph.title, body: paragraph.body, component: component) }
  let!(:amendment) { create :amendment, amendable: paragraph, emendation: emendation }

  let(:emendation_path) { Decidim::ResourceLocatorPresenter.new(emendation).path }
  let(:paragraph_path) { Decidim::ResourceLocatorPresenter.new(paragraph).path }

  before do
    switch_to_host(component.organization.host)
  end

  context "when visiting an amendment to a paragraph" do
    context "and the amendment is being evaluated" do
      before do
        paragraph.update(title: { en: "Updated long enough title" }, body: { en: "Updated one liner body" })
        # The last version of the emendation should hold the amending attribute values.
        emendation.update(title: { en: "Amended long enough title" }, body: { en: "Amended one liner body" })
        visit emendation_path
      end

      it "shows the changed attributes compared to the last version of the amended paragraph" do
        expect(page).to have_content('Amendment to "Updated long enough title"')

        within ".diff-for-title" do
          expect(page).to have_content("TITLE")

          within ".diff > ul > .del" do
            expect(page).to have_content("Updated long enough title")
          end

          within ".diff > ul > .ins" do
            expect(page).to have_content("Amended long enough title")
          end
        end

        within ".diff-for-body" do
          expect(page).to have_content("BODY")

          within ".diff > ul > .del" do
            expect(page).to have_content("Updated one liner body")
          end

          within ".diff > ul > .ins" do
            expect(page).to have_content("Amended one liner body")
          end
        end
      end
    end

    context "and the amendment is NOT being evaluated" do
      before do
        paragraph.update(title: { en: "Updated long enough title" }, body: { en: "Updated one liner body" })
        # The last version of the emendation should hold the amending attribute values.
        emendation.update(title: { en: "Amended long enough title" }, body: { en: "Amended one liner body" })
        amendment.update(state: "withdrawn")
        visit emendation_path
      end

      it "shows the changed attributes compared to the version of the amended paragraph at the moment of making the amendment" do
        expect(page).to have_content('Amendment to "Updated long enough title"')

        within ".diff-for-title" do
          expect(page).to have_content("TITLE")

          within ".diff > ul > .del" do
            expect(page).to have_content("Original long enough title")
          end

          within ".diff > ul > .ins" do
            expect(page).to have_content("Amended long enough title")
          end
        end

        within ".diff-for-body" do
          expect(page).to have_content("BODY")

          within ".diff > ul > .del" do
            expect(page).to have_content("Original one liner body")
          end

          within ".diff > ul > .ins" do
            expect(page).to have_content("Amended one liner body")
          end
        end
      end
    end

    context "and the emendation and the amendable have seemingly the same body but different newline escape sequences" do
      before do
        paragraph.update(body: { en: "One liner body\nAmended" })
        # The last version of the emendation should hold the amending attribute values.
        emendation.update(body: { en: "One liner body\r\nAmended" })
        visit emendation_path
      end

      it "shows NO changes in the body" do
        expect(page).to have_content('Amendment to "Original long enough title"')

        within ".diff-for-body" do
          expect(page).to have_content("BODY")

          within all(".diff > ul > .unchanged").first do
            expect(page).to have_content("One liner body")
          end

          within all(".diff > ul > .unchanged").last do
            expect(page).to have_content("Amended")
          end
        end
      end
    end
  end

  context "when amendment REACTION is enabled" do
    before do
      component.update!(
        settings: { amendments_enabled: true },
        step_settings: {
          component.participatory_space.active_step.id => {
            amendment_reaction_enabled: true
          }
        }
      )
    end

    context "and the paragraph author is reviewing an emendation to their paragraph before accepting it" do
      let(:user) { paragraph.creator_author }

      before do
        paragraph.update(title: { en: "Updated long enough title" }, body: { en: "Updated one liner body" })
        # The last version of the emendation should hold the amending attribute values.
        emendation.update(title: { en: "Amended long enough title" }, body: { en: "Amended one liner body" })
        visit emendation_path
        login_as user, scope: :user
        visit decidim.review_amend_path(amendment)
      end

      it "shows the changed attributes compared to the last version of the amended paragraph" do
        within ".diff-for-title" do
          expect(page).to have_content("TITLE")

          within ".diff > ul > .del" do
            expect(page).to have_content("Updated long enough title")
          end

          within ".diff > ul > .ins" do
            expect(page).to have_content("Amended long enough title")
          end
        end

        within ".diff-for-body" do
          expect(page).to have_content("BODY")

          within ".diff > ul > .del" do
            expect(page).to have_content("Updated one liner body")
          end

          within ".diff > ul > .ins" do
            expect(page).to have_content("Amended one liner body")
          end
        end
      end
    end
  end
end
