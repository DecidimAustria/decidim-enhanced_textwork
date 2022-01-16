# frozen_string_literal: true

require "spec_helper"

module Decidim
  module EnhancedTextwork
    describe ParagraphsController, type: :controller do
      routes { Decidim::EnhancedTextwork::Engine.routes }

      let(:user) { create(:user, :confirmed, organization: component.organization) }

      let(:paragraph_params) do
        {
          component_id: component.id
        }
      end
      let(:params) { { paragraph: paragraph_params } }

      before do
        request.env["decidim.current_organization"] = component.organization
        request.env["decidim.current_participatory_space"] = component.participatory_space
        request.env["decidim.current_component"] = component
      end

      describe "GET index" do
        context "when participatory texts are disabled" do
          let(:component) { create(:paragraph_component, :with_geocoding_enabled) }

          it "sorts paragraphs by search defaults" do
            get :index
            expect(response).to have_http_status(:ok)
            expect(subject).to render_template(:index)
            expect(assigns(:paragraphs).order_values).to eq(
              [
                Decidim::EnhancedTextwork::Paragraph.arel_table[
                  Decidim::EnhancedTextwork::Paragraph.primary_key
                ] * Arel.sql("RANDOM()")
              ]
            )
            expect(assigns(:paragraphs).order_values.map(&:to_sql)).to eq(
              ["\"decidim_enhanced_textwork_paragraphs\".\"id\" * RANDOM()"]
            )
          end

          it "sets two different collections" do
            geocoded_paragraphs = create_list :paragraph, 10, component: component, latitude: 1.1, longitude: 2.2
            _non_geocoded_paragraphs = create_list :paragraph, 2, component: component, latitude: nil, longitude: nil

            get :index
            expect(response).to have_http_status(:ok)
            expect(subject).to render_template(:index)

            expect(assigns(:paragraphs).count).to eq 12
            expect(assigns(:all_geocoded_paragraphs)).to match_array(geocoded_paragraphs)
          end
        end

        context "when participatory texts are enabled" do
          let(:component) { create(:paragraph_component, :with_participatory_texts_enabled) }

          it "sorts paragraphs by position" do
            get :index
            expect(response).to have_http_status(:ok)
            expect(subject).to render_template(:participatory_text)
            expect(assigns(:paragraphs).order_values.first.expr.name).to eq("position")
          end

          context "when emendations exist" do
            let!(:amendable) { create(:paragraph, component: component) }
            let!(:emendation) { create(:paragraph, component: component) }
            let!(:amendment) { create(:amendment, amendable: amendable, emendation: emendation, state: "accepted") }

            it "does not include emendations" do
              get :index
              expect(response).to have_http_status(:ok)
              emendations = assigns(:paragraphs).select(&:emendation?)
              expect(emendations).to be_empty
            end
          end
        end
      end

      describe "GET new" do
        let(:component) { create(:paragraph_component, :with_creation_enabled) }

        before { sign_in user }

        context "when NO draft paragraphs exist" do
          it "renders the empty form" do
            get :new, params: params
            expect(response).to have_http_status(:ok)
            expect(subject).to render_template(:new)
          end
        end

        context "when draft paragraphs exist from other users" do
          let!(:others_draft) { create(:paragraph, :draft, component: component) }

          it "renders the empty form" do
            get :new, params: params
            expect(response).to have_http_status(:ok)
            expect(subject).to render_template(:new)
          end
        end
      end

      describe "POST create" do
        before { sign_in user }

        context "when creation is not enabled" do
          let(:component) { create(:paragraph_component) }

          it "raises an error" do
            post :create, params: params

            expect(flash[:alert]).not_to be_empty
          end
        end

        context "when creation is enabled" do
          let(:component) { create(:paragraph_component, :with_creation_enabled) }
          let(:paragraph_params) do
            {
              component_id: component.id,
              title: "Lorem ipsum dolor sit amet, consectetur adipiscing elit",
              body: "Ut sed dolor vitae purus volutpat venenatis. Donec sit amet sagittis sapien. Curabitur rhoncus ullamcorper feugiat. Aliquam et magna metus."
            }
          end

          it "creates a paragraph" do
            post :create, params: params

            expect(flash[:notice]).not_to be_empty
            expect(response).to have_http_status(:found)
          end
        end
      end

      describe "PATCH update" do
        let(:component) { create(:paragraph_component, :with_creation_enabled, :with_attachments_allowed) }
        let(:paragraph) { create(:paragraph, component: component, users: [user]) }
        let(:paragraph_params) do
          {
            title: "Lorem ipsum dolor sit amet, consectetur adipiscing elit",
            body: "Ut sed dolor vitae purus volutpat venenatis. Donec sit amet sagittis sapien. Curabitur rhoncus ullamcorper feugiat. Aliquam et magna metus."
          }
        end
        let(:params) do
          {
            id: paragraph.id,
            paragraph: paragraph_params
          }
        end

        before { sign_in user }

        it "updates the paragraph" do
          patch :update, params: params

          expect(flash[:notice]).not_to be_empty
          expect(response).to have_http_status(:found)
        end

        context "when the existing paragraph has attachments and there are other errors on the form" do
          include_context "with controller rendering the view" do
            let(:paragraph_params) do
              {
                title: "Short",
                # When the paragraph has existing photos or documents, their IDs
                # will be sent as Strings in the form payload.
                photos: paragraph.photos.map { |a| a.id.to_s },
                documents: paragraph.documents.map { |a| a.id.to_s }
              }
            end
            let(:paragraph) { create(:paragraph, :with_photo, :with_document, component: component, users: [user]) }

            it "displays the editing form with errors" do
              patch :update, params: params

              expect(flash[:alert]).not_to be_empty
              expect(response).to have_http_status(:ok)
              expect(subject).to render_template(:edit)
              expect(response.body).to include("There was a problem saving")
            end
          end
        end
      end

      describe "withdraw a paragraph" do
        let(:component) { create(:paragraph_component, :with_creation_enabled) }

        before { sign_in user }

        context "when an authorized user is withdrawing a paragraph" do
          let(:paragraph) { create(:paragraph, component: component, users: [user]) }

          it "withdraws the paragraph" do
            put :withdraw, params: params.merge(id: paragraph.id)

            expect(flash[:notice]).to eq("Paragraph successfully updated.")
            expect(response).to have_http_status(:found)
            paragraph.reload
            expect(paragraph.withdrawn?).to be true
          end

          context "and the paragraph already has supports" do
            let(:paragraph) { create(:paragraph, :with_votes, component: component, users: [user]) }

            it "is not able to withdraw the paragraph" do
              put :withdraw, params: params.merge(id: paragraph.id)

              expect(flash[:alert]).to eq("This paragraph can not be withdrawn because it already has supports.")
              expect(response).to have_http_status(:found)
              paragraph.reload
              expect(paragraph.withdrawn?).to be false
            end
          end
        end

        describe "when current user is NOT the author of the paragraph" do
          let(:current_user) { create(:user, :confirmed, organization: component.organization) }
          let(:paragraph) { create(:paragraph, component: component, users: [current_user]) }

          context "and the paragraph has no supports" do
            it "is not able to withdraw the paragraph" do
              expect(WithdrawParagraph).not_to receive(:call)

              put :withdraw, params: params.merge(id: paragraph.id)

              expect(flash[:alert]).to eq("You are not authorized to perform this action")
              expect(response).to have_http_status(:found)
              paragraph.reload
              expect(paragraph.withdrawn?).to be false
            end
          end
        end
      end

      describe "GET show" do
        let!(:component) { create(:paragraph_component, :with_amendments_enabled) }
        let!(:amendable) { create(:paragraph, component: component) }
        let!(:emendation) { create(:paragraph, component: component) }
        let!(:amendment) { create(:amendment, amendable: amendable, emendation: emendation) }
        let(:active_step_id) { component.participatory_space.active_step.id }

        context "when the paragraph is an amendable" do
          it "shows the paragraph" do
            get :show, params: params.merge(id: amendable.id)
            expect(response).to have_http_status(:ok)
            expect(subject).to render_template(:show)
          end

          context "and the user is not logged in" do
            it "shows the paragraph" do
              get :show, params: params.merge(id: amendable.id)
              expect(response).to have_http_status(:ok)
              expect(subject).to render_template(:show)
            end
          end
        end

        context "when the paragraph is an emendation" do
          context "and amendments VISIBILITY is set to 'participants'" do
            before do
              component.update!(step_settings: { active_step_id => { amendments_visibility: "participants" } })
            end

            context "when the user is not logged in" do
              it "redirects to 404" do
                expect do
                  get :show, params: params.merge(id: emendation.id)
                end.to raise_error(ActionController::RoutingError)
              end
            end

            context "when the user is logged in" do
              before { sign_in user }

              context "and the user is the author of the emendation" do
                let(:user) { amendment.amender }

                it "shows the paragraph" do
                  get :show, params: params.merge(id: emendation.id)
                  expect(response).to have_http_status(:ok)
                  expect(subject).to render_template(:show)
                end
              end

              context "and is NOT the author of the emendation" do
                it "redirects to 404" do
                  expect do
                    get :show, params: params.merge(id: emendation.id)
                  end.to raise_error(ActionController::RoutingError)
                end

                context "when the user is an admin" do
                  let(:user) { create(:user, :admin, :confirmed, organization: component.organization) }

                  it "shows the paragraph" do
                    get :show, params: params.merge(id: emendation.id)
                    expect(response).to have_http_status(:ok)
                    expect(subject).to render_template(:show)
                  end
                end
              end
            end
          end

          context "and amendments VISIBILITY is set to 'all'" do
            before do
              component.update!(step_settings: { active_step_id => { amendments_visibility: "all" } })
            end

            context "when the user is not logged in" do
              it "shows the paragraph" do
                get :show, params: params.merge(id: emendation.id)
                expect(response).to have_http_status(:ok)
                expect(subject).to render_template(:show)
              end
            end

            context "when the user is logged in" do
              before { sign_in user }

              context "and is NOT the author of the emendation" do
                it "shows the paragraph" do
                  get :show, params: params.merge(id: emendation.id)
                  expect(response).to have_http_status(:ok)
                  expect(subject).to render_template(:show)
                end
              end
            end
          end
        end
      end
    end
  end
end
