# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      # This controller allows admins to answer paragraphs in a participatory process.
      class ParagraphAnswersController < Admin::ApplicationController
        helper_method :paragraph

        helper EnhancedTextwork::ApplicationHelper
        helper Decidim::EnhancedTextwork::Admin::ParagraphsHelper
        helper Decidim::EnhancedTextwork::Admin::ParagraphRankingsHelper
        helper Decidim::Messaging::ConversationHelper

        def edit
          enforce_permission_to :create, :paragraph_answer, paragraph: paragraph
          @form = form(Admin::ParagraphAnswerForm).from_model(paragraph)
        end

        def update
          enforce_permission_to :create, :paragraph_answer, paragraph: paragraph
          @notes_form = form(ParagraphNoteForm).instance
          @answer_form = form(Admin::ParagraphAnswerForm).from_params(params)

          Admin::AnswerParagraph.call(@answer_form, paragraph) do
            on(:ok) do
              flash[:notice] = I18n.t("paragraphs.answer.success", scope: "decidim.enhanced_textwork.admin")
              redirect_to paragraphs_path
            end

            on(:invalid) do
              flash.keep[:alert] = I18n.t("paragraphs.answer.invalid", scope: "decidim.enhanced_textwork.admin")
              render template: "decidim/enhanced_textwork/admin/paragraphs/show"
            end
          end
        end

        private

        def skip_manage_component_permission
          true
        end

        def paragraph
          @paragraph ||= Paragraph.where(component: current_component).find(params[:id])
        end
      end
    end
  end
end
