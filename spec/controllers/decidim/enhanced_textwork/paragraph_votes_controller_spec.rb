# frozen_string_literal: true

require "spec_helper"

module Decidim
  module EnhancedTextwork
    describe ParagraphVotesController, type: :controller do
      routes { Decidim::EnhancedTextwork::Engine.routes }

      let(:paragraph) { create(:paragraph, component: component) }
      let(:user) { create(:user, :confirmed, organization: component.organization) }

      let(:params) do
        {
          paragraph_id: paragraph.id,
          component_id: component.id
        }
      end

      before do
        request.env["decidim.current_organization"] = component.organization
        request.env["decidim.current_participatory_space"] = component.participatory_space
        request.env["decidim.current_component"] = component
        sign_in user
      end

      describe "POST create" do
        context "with votes enabled" do
          let(:component) do
            create(:paragraph_component, :with_votes_enabled)
          end

          it "allows voting" do
            expect do
              post :create, format: :js, params: params
            end.to change(ParagraphVote, :count).by(1)

            expect(ParagraphVote.last.author).to eq(user)
            expect(ParagraphVote.last.paragraph).to eq(paragraph)
          end
        end

        context "with votes disabled" do
          let(:component) do
            create(:paragraph_component)
          end

          it "doesn't allow voting" do
            expect do
              post :create, format: :js, params: params
            end.not_to change(ParagraphVote, :count)

            expect(flash[:alert]).not_to be_empty
            expect(response).to have_http_status(:found)
          end
        end

        context "with votes enabled but votes blocked" do
          let(:component) do
            create(:paragraph_component, :with_votes_blocked)
          end

          it "doesn't allow voting" do
            expect do
              post :create, format: :js, params: params
            end.not_to change(ParagraphVote, :count)

            expect(flash[:alert]).not_to be_empty
            expect(response).to have_http_status(:found)
          end
        end
      end

      describe "destroy" do
        before do
          create(:paragraph_vote, paragraph: paragraph, author: user)
        end

        context "with vote limit enabled" do
          let(:component) do
            create(:paragraph_component, :with_votes_enabled, :with_vote_limit)
          end

          it "deletes the vote" do
            expect do
              delete :destroy, format: :js, params: params
            end.to change(ParagraphVote, :count).by(-1)

            expect(ParagraphVote.count).to eq(0)
          end
        end

        context "with vote limit disabled" do
          let(:component) do
            create(:paragraph_component, :with_votes_enabled)
          end

          it "deletes the vote" do
            expect do
              delete :destroy, format: :js, params: params
            end.to change(ParagraphVote, :count).by(-1)

            expect(ParagraphVote.count).to eq(0)
          end
        end
      end
    end
  end
end
