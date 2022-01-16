# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    # Exposes the paragraph vote resource so users can vote paragraphs.
    class ParagraphVotesController < Decidim::EnhancedTextwork::ApplicationController
      include ParagraphVotesHelper
      include Rectify::ControllerHelpers

      helper_method :paragraph

      before_action :authenticate_user!

      def create
        enforce_permission_to :vote, :paragraph, paragraph: paragraph
        @from_paragraphs_list = params[:from_paragraphs_list] == "true"
        @chevron_button = params[:chevron_button] == "true"

        VoteParagraph.call(paragraph, current_user) do
          on(:ok) do
            paragraph.reload

            paragraphs = ParagraphVote.where(
              author: current_user,
              paragraph: Paragraph.where(component: current_component)
            ).map(&:paragraph)

            expose(paragraphs: paragraphs)
            render :update_buttons_and_counters
          end

          on(:invalid) do
            render json: { error: I18n.t("paragraph_votes.create.error", scope: "decidim.enhanced_textwork") }, status: :unprocessable_entity
          end
        end
      end

      def destroy
        enforce_permission_to :unvote, :paragraph, paragraph: paragraph
        @from_paragraphs_list = params[:from_paragraphs_list] == "true"
        @chevron_button = params[:chevron_button] == "true"

        UnvoteParagraph.call(paragraph, current_user) do
          on(:ok) do
            paragraph.reload

            paragraphs = ParagraphVote.where(
              author: current_user,
              paragraph: Paragraph.where(component: current_component)
            ).map(&:paragraph)

            expose(paragraphs: paragraphs + [paragraph])
            render :update_buttons_and_counters
          end
        end
      end

      private

      def paragraph
        @paragraph ||= Paragraph.where(component: current_component).find(params[:paragraph_id])
      end
    end
  end
end
