# frozen_string_literal: true

shared_examples "manage paragraphs" do
  let(:address) { "Some address" }
  let(:latitude) { 40.1234 }
  let(:longitude) { 2.1234 }
  let(:participatory_process) { create(:participatory_process, :with_steps, organization: organization, scope: participatory_process_scope) }
  let(:participatory_process_scope) { nil }
  let(:paragraph_title) { translated(paragraph.title) }

  before do
    stub_geocoding(address, [latitude, longitude])
  end

  context "when previewing paragraphs" do
    it "allows the user to preview the paragraph" do
      within find("tr", text: paragraph_title) do
        klass = "action-icon--preview"
        href = resource_locator(paragraph).path
        target = "blank"

        expect(page).to have_selector(
          :xpath,
          "//a[contains(@class,'#{klass}')][@href='#{href}'][@target='#{target}']"
        )
      end
    end
  end

  describe "creation" do
    context "when official_paragraphs setting is enabled" do
      before do
        current_component.update!(settings: { official_paragraphs_enabled: true })
      end

      context "when creation is enabled" do
        before do
          current_component.update!(
            step_settings: {
              current_component.participatory_space.active_step.id => {
                creation_enabled: true
              }
            }
          )

          visit_component_admin
        end

        describe "admin form" do
          before { click_on "New paragraph" }

          it_behaves_like "having a rich text editor", "new_paragraph", "full"
        end

        context "when process is not related to any scope" do
          it "can be related to a scope" do
            click_link "New paragraph"

            within "form" do
              expect(page).to have_content(/Scope/i)
            end
          end

          it "creates a new paragraph", :slow do
            click_link "New paragraph"

            within ".new_paragraph" do
              fill_in_i18n :paragraph_title, "#paragraph-title-tabs", en: "Make decidim great again"
              fill_in_i18n_editor :paragraph_body, "#paragraph-body-tabs", en: "Decidim is great but it can be better"
              select translated(category.name), from: :paragraph_category_id
              scope_pick select_data_picker(:paragraph_scope_id), scope
              find("*[type=submit]").click
            end

            expect(page).to have_admin_callout("successfully")

            within "table" do
              paragraph = Decidim::EnhancedTextwork::Paragraph.last

              expect(page).to have_content("Make decidim great again")
              expect(translated(paragraph.body)).to eq("<p>Decidim is great but it can be better</p>")
              expect(paragraph.category).to eq(category)
              expect(paragraph.scope).to eq(scope)
            end
          end
        end

        context "when process is related to a scope" do
          before do
            component.update!(settings: { scopes_enabled: false })
          end

          let(:participatory_process_scope) { scope }

          it "cannot be related to a scope, because it has no children" do
            click_link "New paragraph"

            within "form" do
              expect(page).to have_no_content(/Scope/i)
            end
          end

          it "creates a new paragraph related to the process scope" do
            click_link "New paragraph"

            within ".new_paragraph" do
              fill_in_i18n :paragraph_title, "#paragraph-title-tabs", en: "Make decidim great again"
              fill_in_i18n_editor :paragraph_body, "#paragraph-body-tabs", en: "Decidim is great but it can be better"
              select category.name["en"], from: :paragraph_category_id
              find("*[type=submit]").click
            end

            expect(page).to have_admin_callout("successfully")

            within "table" do
              paragraph = Decidim::EnhancedTextwork::Paragraph.last

              expect(page).to have_content("Make decidim great again")
              expect(translated(paragraph.body)).to eq("<p>Decidim is great but it can be better</p>")
              expect(paragraph.category).to eq(category)
              expect(paragraph.scope).to eq(scope)
            end
          end

          context "when the process scope has a child scope" do
            let!(:child_scope) { create :scope, parent: scope }

            it "can be related to a scope" do
              click_link "New paragraph"

              within "form" do
                expect(page).to have_content(/Scope/i)
              end
            end

            it "creates a new paragraph related to a process scope child" do
              click_link "New paragraph"

              within ".new_paragraph" do
                fill_in_i18n :paragraph_title, "#paragraph-title-tabs", en: "Make decidim great again"
                fill_in_i18n_editor :paragraph_body, "#paragraph-body-tabs", en: "Decidim is great but it can be better"
                select category.name["en"], from: :paragraph_category_id
                scope_repick :paragraph_scope_id, scope, child_scope
                find("*[type=submit]").click
              end

              expect(page).to have_admin_callout("successfully")

              within "table" do
                paragraph = Decidim::EnhancedTextwork::Paragraph.last

                expect(page).to have_content("Make decidim great again")
                expect(translated(paragraph.body)).to eq("<p>Decidim is great but it can be better</p>")
                expect(paragraph.category).to eq(category)
                expect(paragraph.scope).to eq(child_scope)
              end
            end
          end

          context "when geocoding is enabled", :serves_geocoding_autocomplete do
            before do
              current_component.update!(settings: { geocoding_enabled: true })
            end

            it "creates a new paragraph related to the process scope" do
              click_link "New paragraph"

              within ".new_paragraph" do
                fill_in_i18n :paragraph_title, "#paragraph-title-tabs", en: "Make decidim great again"
                fill_in_i18n_editor :paragraph_body, "#paragraph-body-tabs", en: "Decidim is great but it can be better"
                fill_in :paragraph_address, with: address
                select category.name["en"], from: :paragraph_category_id
                find("*[type=submit]").click
              end

              expect(page).to have_admin_callout("successfully")

              within "table" do
                paragraph = Decidim::EnhancedTextwork::Paragraph.last

                expect(page).to have_content("Make decidim great again")
                expect(translated(paragraph.body)).to eq("<p>Decidim is great but it can be better</p>")
                expect(paragraph.category).to eq(category)
                expect(paragraph.scope).to eq(scope)
              end
            end

            it_behaves_like(
              "a record with front-end geocoding address field",
              Decidim::EnhancedTextwork::Paragraph,
              within_selector: ".new_paragraph",
              address_field: :paragraph_address
            ) do
              let(:geocoded_address_value) { address }
              let(:geocoded_address_coordinates) { [latitude, longitude] }

              before do
                click_link "New paragraph"

                within ".new_paragraph" do
                  fill_in_i18n :paragraph_title, "#paragraph-title-tabs", en: "Make decidim great again"
                  fill_in_i18n_editor :paragraph_body, "#paragraph-body-tabs", en: "Decidim is great but it can be better"
                end
              end
            end
          end
        end

        context "when attachments are allowed" do
          before do
            current_component.update!(settings: { attachments_allowed: true })
          end

          it "creates a new paragraph with attachments" do
            click_link "New paragraph"

            within ".new_paragraph" do
              fill_in_i18n :paragraph_title, "#paragraph-title-tabs", en: "Paragraph with attachments"
              fill_in_i18n_editor :paragraph_body, "#paragraph-body-tabs", en: "This is my paragraph and I want to upload attachments."
              fill_in :paragraph_attachment_title, with: "My attachment"
              attach_file :paragraph_attachment_file, Decidim::Dev.asset("city.jpeg")
              find("*[type=submit]").click
            end

            expect(page).to have_admin_callout("successfully")

            visit resource_locator(Decidim::EnhancedTextwork::Paragraph.last).path
            expect(page).to have_selector("img[src*=\"city.jpeg\"]", count: 1)
          end
        end

        context "when paragraphs comes from a meeting" do
          let!(:meeting_component) { create(:meeting_component, participatory_space: participatory_process) }
          let!(:meetings) { create_list(:meeting, 3, component: meeting_component) }

          it "creates a new paragraph with meeting as author" do
            click_link "New paragraph"

            within ".new_paragraph" do
              fill_in_i18n :paragraph_title, "#paragraph-title-tabs", en: "Paragraph with meeting as author"
              fill_in_i18n_editor :paragraph_body, "#paragraph-body-tabs", en: "Paragraph body of meeting as author"
              execute_script("$('#paragraph_created_in_meeting').change()")
              find(:css, "#paragraph_created_in_meeting").set(true)
              select translated(meetings.first.title), from: :paragraph_meeting_id
              select category.name["en"], from: :paragraph_category_id
              find("*[type=submit]").click
            end

            expect(page).to have_admin_callout("successfully")

            within "table" do
              paragraph = Decidim::EnhancedTextwork::Paragraph.last

              expect(page).to have_content("Paragraph with meeting as author")
              expect(translated(paragraph.body)).to eq("<p>Paragraph body of meeting as author</p>")
              expect(paragraph.category).to eq(category)
            end
          end
        end
      end

      context "when creation is not enabled" do
        before do
          current_component.update!(
            step_settings: {
              current_component.participatory_space.active_step.id => {
                creation_enabled: false
              }
            }
          )
        end

        it "cannot create a new paragraph from the main site" do
          visit_component
          expect(page).to have_no_button("New Paragraph")
        end

        it "cannot create a new paragraph from the admin site" do
          visit_component_admin
          expect(page).to have_no_link(/New/)
        end
      end
    end

    context "when official_paragraphs setting is disabled" do
      before do
        current_component.update!(settings: { official_paragraphs_enabled: false })
      end

      it "cannot create a new paragraph from the main site" do
        visit_component
        expect(page).to have_no_button("New Paragraph")
      end

      it "cannot create a new paragraph from the admin site" do
        visit_component_admin
        expect(page).to have_no_link(/New/)
      end
    end
  end

  context "when the paragraph_answering component setting is enabled" do
    before do
      current_component.update!(settings: { paragraph_answering_enabled: true })
    end

    context "when the paragraph_answering step setting is enabled" do
      before do
        current_component.update!(
          step_settings: {
            current_component.participatory_space.active_step.id => {
              paragraph_answering_enabled: true
            }
          }
        )
      end

      it "can reject a paragraph" do
        go_to_admin_paragraph_page_answer_section(paragraph)

        within ".edit_paragraph_answer" do
          fill_in_i18n_editor(
            :paragraph_answer_answer,
            "#paragraph_answer-answer-tabs",
            en: "The paragraph doesn't make any sense",
            es: "La propuesta no tiene sentido",
            ca: "La proposta no te sentit"
          )
          choose "Rejected"
          click_button "Answer"
        end

        expect(page).to have_admin_callout("Paragraph successfully answered")

        within find("tr", text: paragraph_title) do
          expect(page).to have_content("Rejected")
        end
      end

      it "can accept a paragraph" do
        go_to_admin_paragraph_page_answer_section(paragraph)

        within ".edit_paragraph_answer" do
          choose "Accepted"
          click_button "Answer"
        end

        expect(page).to have_admin_callout("Paragraph successfully answered")

        within find("tr", text: paragraph_title) do
          expect(page).to have_content("Accepted")
        end
      end

      it "can mark a paragraph as evaluating" do
        go_to_admin_paragraph_page_answer_section(paragraph)

        within ".edit_paragraph_answer" do
          choose "Evaluating"
          click_button "Answer"
        end

        expect(page).to have_admin_callout("Paragraph successfully answered")

        within find("tr", text: paragraph_title) do
          expect(page).to have_content("Evaluating")
        end
      end

      it "can edit a paragraph answer" do
        paragraph.update!(
          state: "rejected",
          answer: {
            "en" => "I don't like it"
          },
          answered_at: Time.current
        )

        visit_component_admin

        within find("tr", text: paragraph_title) do
          expect(page).to have_content("Rejected")
        end

        go_to_admin_paragraph_page_answer_section(paragraph)

        within ".edit_paragraph_answer" do
          choose "Accepted"
          click_button "Answer"
        end

        expect(page).to have_admin_callout("Paragraph successfully answered")

        within find("tr", text: paragraph_title) do
          expect(page).to have_content("Accepted")
        end
      end
    end

    context "when the paragraph_answering step setting is disabled" do
      before do
        current_component.update!(
          step_settings: {
            current_component.participatory_space.active_step.id => {
              paragraph_answering_enabled: false
            }
          }
        )
      end

      it "cannot answer a paragraph" do
        visit current_path

        within find("tr", text: paragraph_title) do
          expect(page).to have_no_link("Answer")
        end
      end
    end

    context "when the paragraph is an emendation" do
      let!(:amendable) { create(:paragraph, component: current_component) }
      let!(:emendation) { create(:paragraph, component: current_component) }
      let!(:amendment) { create :amendment, amendable: amendable, emendation: emendation, state: "evaluating" }

      it "cannot answer a paragraph" do
        visit_component_admin
        within find("tr", text: I18n.t("decidim/amendment", scope: "activerecord.models", count: 1)) do
          expect(page).to have_no_link("Answer")
        end
      end
    end
  end

  context "when the paragraph_answering component setting is disabled" do
    before do
      current_component.update!(settings: { paragraph_answering_enabled: false })
    end

    it "cannot answer a paragraph" do
      go_to_admin_paragraph_page(paragraph)

      expect(page).to have_no_selector(".edit_paragraph_answer")
    end
  end

  context "when the votes_enabled component setting is disabled" do
    before do
      current_component.update!(
        step_settings: {
          component.participatory_space.active_step.id => {
            votes_enabled: false
          }
        }
      )
    end

    it "doesn't show the votes column" do
      visit current_path

      within "thead" do
        expect(page).not_to have_content("VOTES")
      end
    end
  end

  context "when the votes_enabled component setting is enabled" do
    before do
      current_component.update!(
        step_settings: {
          component.participatory_space.active_step.id => {
            votes_enabled: true
          }
        }
      )
    end

    it "shows the votes column" do
      visit current_path

      within "thead" do
        expect(page).to have_content("Votes")
      end
    end
  end

  def go_to_admin_paragraph_page(paragraph)
    paragraph_title = translated(paragraph.title)
    within find("tr", text: paragraph_title) do
      find("a", class: "action-icon--show-paragraph").click
    end
  end

  def go_to_admin_paragraph_page_answer_section(paragraph)
    go_to_admin_paragraph_page(paragraph)

    expect(page).to have_selector(".edit_paragraph_answer")
  end
end
