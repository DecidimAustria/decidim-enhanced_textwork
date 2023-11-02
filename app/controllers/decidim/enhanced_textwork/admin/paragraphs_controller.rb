# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      # This controller allows admins to manage paragraphs in a participatory process.
      class ParagraphsController < Admin::ApplicationController
        include Decidim::ApplicationHelper
        include Decidim::EnhancedTextwork::Admin::Filterable

        helper EnhancedTextwork::ApplicationHelper
        helper Decidim::EnhancedTextwork::Admin::ParagraphRankingsHelper
        helper Decidim::Messaging::ConversationHelper
        helper_method :paragraphs, :query, :form_presenter, :paragraph, :paragraph_ids
        helper EnhancedTextwork::Admin::ParagraphBulkActionsHelper

        def show
          @notes_form = form(ParagraphNoteForm).instance
          @answer_form = form(Admin::ParagraphAnswerForm).from_model(paragraph)
        end

        def new
          enforce_permission_to :create, :paragraph
          @form = form(Decidim::EnhancedTextwork::Admin::ParagraphForm).from_params(
            attachment: form(AttachmentForm).from_params({})
          )
        end

        def create
          enforce_permission_to :create, :paragraph
          @form = form(Decidim::EnhancedTextwork::Admin::ParagraphForm).from_params(params)

          Admin::CreateParagraph.call(@form) do
            on(:ok) do
              flash[:notice] = I18n.t("paragraphs.create.success", scope: "decidim.enhanced_textwork.admin")
              redirect_to paragraphs_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("paragraphs.create.invalid", scope: "decidim.enhanced_textwork.admin")
              render action: "new"
            end
          end
        end

        def update_category
          enforce_permission_to :update, :paragraph_category

          Admin::UpdateParagraphCategory.call(params[:category][:id], paragraph_ids) do
            on(:invalid_category) do
              flash.now[:error] = I18n.t(
                "paragraphs.update_category.select_a_category",
                scope: "decidim.enhanced_textwork.admin"
              )
            end

            on(:invalid_paragraph_ids) do
              flash.now[:alert] = I18n.t(
                "paragraphs.update_category.select_a_paragraph",
                scope: "decidim.enhanced_textwork.admin"
              )
            end

            on(:update_paragraphs_category) do
              flash.now[:notice] = update_paragraphs_bulk_response_successful(@response, :category)
              flash.now[:alert] = update_paragraphs_bulk_response_errored(@response, :category)
            end
            respond_to do |format|
              format.js
            end
          end
        end

        def publish_answers
          enforce_permission_to :publish_answers, :paragraphs

          Decidim::EnhancedTextwork::Admin::PublishAnswers.call(current_component, current_user, paragraph_ids) do
            on(:invalid) do
              flash.now[:alert] = t(
                "paragraphs.publish_answers.select_a_paragraph",
                scope: "decidim.enhanced_textwork.admin"
              )
            end

            on(:ok) do
              flash.now[:notice] = I18n.t("enhanced_textwork.publish_answers.success", scope: "decidim")
            end
          end

          respond_to do |format|
            format.js
          end
        end

        def update_scope
          enforce_permission_to :update, :paragraph_scope

          Admin::UpdateParagraphScope.call(params[:scope_id], paragraph_ids) do
            on(:invalid_scope) do
              flash.now[:error] = t(
                "paragraphs.update_scope.select_a_scope",
                scope: "decidim.enhanced_textwork.admin"
              )
            end

            on(:invalid_paragraph_ids) do
              flash.now[:alert] = t(
                "paragraphs.update_scope.select_a_paragraph",
                scope: "decidim.enhanced_textwork.admin"
              )
            end

            on(:update_paragraphs_scope) do
              flash.now[:notice] = update_paragraphs_bulk_response_successful(@response, :scope)
              flash.now[:alert] = update_paragraphs_bulk_response_errored(@response, :scope)
            end

            respond_to do |format|
              format.js
            end
          end
        end

        def edit
          enforce_permission_to :edit, :paragraph, paragraph: paragraph
          @form = form(Admin::ParagraphForm).from_model(paragraph)
        end

        def update
          enforce_permission_to :edit, :paragraph, paragraph: paragraph

          @form = form(Admin::ParagraphForm).from_params(params)

          Admin::UpdateParagraph.call(@form, @paragraph) do
            on(:ok) do |_paragraph|
              flash[:notice] = I18n.t("decidim.enhanced_textwork.update.success", scope: "decidim")
              redirect_to paragraphs_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("decidim.enhanced_textwork.update.error", scope: "decidim")
              render :edit
            end
          end
        end

        def destroy_draft
          enforce_permission_to :edit, :paragraph, paragraph: draft

          Admin::DestroyParagraph.call(draft) do
            on(:ok) do
              flash[:notice] = I18n.t("enhanced_textwork.destroy_draft.success", scope: "decidim")
              redirect_to participatory_texts_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("enhanced_textwork.destroy_draft.error", scope: "decidim")
              redirect_to participatory_texts_path
            end
          end
        end

        private

        def collection
          @collection ||= Paragraph.where(component: current_component).not_hidden.published
        end

        def paragraphs
          @paragraphs ||= filtered_collection
        end

        def paragraph
          @paragraph ||= collection.find(params[:id])
        end

        def paragraph_ids
          @paragraph_ids ||= params[:paragraph_ids]
        end

        def drafts
          Paragraph.where(component: current_component).drafts
        end

        def draft
          @draft ||= drafts.find(params[:id])
        end

        def update_paragraphs_bulk_response_successful(response, subject)
          return if response[:successful].blank?

          case subject
          when :category
            t(
              "paragraphs.update_category.success",
              subject_name: response[:subject_name],
              paragraphs: response[:successful].to_sentence,
              scope: "decidim.enhanced_textwork.admin"
            )
          when :scope
            t(
              "paragraphs.update_scope.success",
              subject_name: response[:subject_name],
              paragraphs: response[:successful].to_sentence,
              scope: "decidim.enhanced_textwork.admin"
            )
          end
        end

        def update_paragraphs_bulk_response_errored(response, subject)
          return if response[:errored].blank?

          case subject
          when :category
            t(
              "paragraphs.update_category.invalid",
              subject_name: response[:subject_name],
              paragraphs: response[:errored].to_sentence,
              scope: "decidim.enhanced_textwork.admin"
            )
          when :scope
            t(
              "paragraphs.update_scope.invalid",
              subject_name: response[:subject_name],
              paragraphs: response[:errored].to_sentence,
              scope: "decidim.enhanced_textwork.admin"
            )
          end
        end

        def form_presenter
          @form_presenter ||= present(@form, presenter_class: Decidim::EnhancedTextwork::ParagraphPresenter)
        end
      end
    end
  end
end
