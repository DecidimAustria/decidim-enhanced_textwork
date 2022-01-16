# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    # Exposes the paragraph resource so users can view and create them.
    class ParagraphsController < Decidim::EnhancedTextwork::ApplicationController
      helper Decidim::WidgetUrlsHelper
      helper ParagraphWizardHelper
      helper ParticipatoryTextsHelper
      helper UserGroupHelper
      include Decidim::ApplicationHelper
      include Flaggable
      include Withdrawable
      include FormFactory
      include FilterResource
      include Decidim::EnhancedTextwork::Orderable
      include Paginable

      helper_method :paragraph_presenter, :form_presenter

      before_action :authenticate_user!, only: [:new, :create, :complete]
      before_action :ensure_is_draft, only: [:compare, :complete, :preview, :publish, :edit_draft, :update_draft, :destroy_draft]
      before_action :set_paragraph, only: [:show, :edit, :update, :withdraw, :overview]
      before_action :edit_form, only: [:edit_draft, :edit]

      before_action :set_participatory_text

      def index
        if component_settings.participatory_texts_enabled?
          @paragraphs = Decidim::EnhancedTextwork::Paragraph
                       .where(component: current_component)
                       .published
                       .not_hidden
                       .only_amendables
                       .includes(:category, :scope)
                       .order(position: :asc)
          render "decidim/enhanced_textwork/paragraphs/participatory_texts/participatory_text"
        else
          @base_query = search
                        .results
                        .published
                        .not_hidden

          @paragraphs = @base_query.includes(:component, :coauthorships)
          @all_geocoded_paragraphs = @base_query.geocoded

          @voted_paragraphs = if current_user
                               ParagraphVote.where(
                                 author: current_user,
                                 paragraph: @paragraphs.pluck(:id)
                               ).pluck(:decidim_paragraph_id)
                             else
                               []
                             end
          @paragraphs = paginate(@paragraphs)
          @paragraphs = reorder(@paragraphs)
        end
      end

      def show
        raise ActionController::RoutingError, "Not Found" if @paragraph.blank? || !can_show_paragraph?
      end

      def overview
        @paragraphs = Decidim::EnhancedTextwork::Paragraph
                     .where(component: current_component)
                     .published
                     .not_hidden
                     .only_amendables
                     .includes(:category, :scope)
                     .order(position: :asc)

        @amendments = @paragraph.amendments.order(created_at: :desc)

        paragraph = @paragraphs.find(params[:id])

        raise ActionController::RoutingError, "Not Found" if paragraph.blank? || !can_show_paragraph?

        render "decidim/enhanced_textwork/paragraphs/participatory_texts/participatory_text", locals: { active_paragraph: paragraph }
      end

      def new
        enforce_permission_to :create, :paragraph
        @step = :step_1
        if paragraph_draft.present?
          redirect_to edit_draft_paragraph_path(paragraph_draft, component_id: paragraph_draft.component.id, question_slug: paragraph_draft.component.participatory_space.slug)
        else
          @form = form(ParagraphWizardCreateStepForm).from_params(body: translated_paragraph_body_template)
        end
      end

      def create
        enforce_permission_to :create, :paragraph
        @step = :step_1
        @form = form(ParagraphWizardCreateStepForm).from_params(paragraph_creation_params)

        CreateParagraph.call(@form, current_user) do
          on(:ok) do |paragraph|
            flash[:notice] = I18n.t("paragraphs.create.success", scope: "decidim")

            redirect_to "#{Decidim::ResourceLocatorPresenter.new(paragraph).path}/compare"
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("paragraphs.create.error", scope: "decidim")
            render :new
          end
        end
      end

      def compare
        @step = :step_2
        @similar_paragraphs ||= Decidim::EnhancedTextwork::SimilarParagraphs
                               .for(current_component, @paragraph)
                               .all

        if @similar_paragraphs.blank?
          flash[:notice] = I18n.t("paragraphs.paragraphs.compare.no_similars_found", scope: "decidim")
          redirect_to "#{Decidim::ResourceLocatorPresenter.new(@paragraph).path}/complete"
        end
      end

      def complete
        enforce_permission_to :create, :paragraph
        @step = :step_3

        @form = form_paragraph_model

        @form.attachment = form_attachment_new
      end

      def preview
        @step = :step_4
        @form = form(ParagraphForm).from_model(@paragraph)
      end

      def publish
        @step = :step_4
        PublishParagraph.call(@paragraph, current_user) do
          on(:ok) do
            flash[:notice] = I18n.t("paragraphs.publish.success", scope: "decidim")
            redirect_to paragraph_path(@paragraph)
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("paragraphs.publish.error", scope: "decidim")
            render :edit_draft
          end
        end
      end

      def edit_draft
        @step = :step_3
        enforce_permission_to :edit, :paragraph, paragraph: @paragraph
      end

      def update_draft
        @step = :step_1
        enforce_permission_to :edit, :paragraph, paragraph: @paragraph

        @form = form_paragraph_params
        UpdateParagraph.call(@form, current_user, @paragraph) do
          on(:ok) do |paragraph|
            flash[:notice] = I18n.t("paragraphs.update_draft.success", scope: "decidim")
            redirect_to "#{Decidim::ResourceLocatorPresenter.new(paragraph).path}/preview"
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("paragraphs.update_draft.error", scope: "decidim")
            render :edit_draft
          end
        end
      end

      def destroy_draft
        enforce_permission_to :edit, :paragraph, paragraph: @paragraph

        DestroyParagraph.call(@paragraph, current_user) do
          on(:ok) do
            flash[:notice] = I18n.t("paragraphs.destroy_draft.success", scope: "decidim")
            redirect_to new_paragraph_path
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("paragraphs.destroy_draft.error", scope: "decidim")
            render :edit_draft
          end
        end
      end

      def edit
        enforce_permission_to :edit, :paragraph, paragraph: @paragraph
      end

      def update
        enforce_permission_to :edit, :paragraph, paragraph: @paragraph

        @form = form_paragraph_params
        UpdateParagraph.call(@form, current_user, @paragraph) do
          on(:ok) do |paragraph|
            flash[:notice] = I18n.t("paragraphs.update.success", scope: "decidim")
            redirect_to Decidim::ResourceLocatorPresenter.new(paragraph).path
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("paragraphs.update.error", scope: "decidim")
            render :edit
          end
        end
      end

      def withdraw
        enforce_permission_to :withdraw, :paragraph, paragraph: @paragraph

        WithdrawParagraph.call(@paragraph, current_user) do
          on(:ok) do
            flash[:notice] = I18n.t("paragraphs.update.success", scope: "decidim")
            redirect_to Decidim::ResourceLocatorPresenter.new(@paragraph).path
          end
          on(:has_supports) do
            flash[:alert] = I18n.t("paragraphs.withdraw.errors.has_supports", scope: "decidim")
            redirect_to Decidim::ResourceLocatorPresenter.new(@paragraph).path
          end
        end
      end

      private

      def search_klass
        ParagraphSearch
      end

      def default_filter_params
        {
          search_text: "",
          origin: default_filter_origin_params,
          activity: "all",
          category_id: default_filter_category_params,
          state: %w(accepted evaluating state_not_published),
          scope_id: default_filter_scope_params,
          related_to: "",
          type: "all"
        }
      end

      def default_filter_origin_params
        filter_origin_params = %w(citizens meeting)
        filter_origin_params << "official" if component_settings.official_paragraphs_enabled
        filter_origin_params << "user_group" if current_organization.user_groups_enabled?
        filter_origin_params
      end

      def paragraph_draft
        Paragraph.from_all_author_identities(current_user).not_hidden.only_amendables
                .where(component: current_component).find_by(published_at: nil)
      end

      def ensure_is_draft
        @paragraph = Paragraph.not_hidden.where(component: current_component).find(params[:id])
        redirect_to Decidim::ResourceLocatorPresenter.new(@paragraph).path unless @paragraph.draft?
      end

      def set_paragraph
        @paragraph = Paragraph.published.not_hidden.where(component: current_component).find_by(id: params[:id])
      end

      # Returns true if the paragraph is NOT an emendation or the user IS an admin.
      # Returns false if the paragraph is not found or the paragraph IS an emendation
      # and is NOT visible to the user based on the component's amendments settings.
      def can_show_paragraph?
        return true if @paragraph&.amendable? || current_user&.admin?

        Paragraph.only_visible_emendations_for(current_user, current_component).published.include?(@paragraph)
      end

      def paragraph_presenter
        @paragraph_presenter ||= present(@paragraph)
      end

      def form_paragraph_params
        form(ParagraphForm).from_params(params)
      end

      def form_paragraph_model
        form(ParagraphForm).from_model(@paragraph)
      end

      def form_presenter
        @form_presenter ||= present(@form, presenter_class: Decidim::EnhancedTextwork::ParagraphPresenter)
      end

      def form_attachment_new
        form(AttachmentForm).from_model(Attachment.new)
      end

      def edit_form
        form_attachment_model = form(AttachmentForm).from_model(@paragraph.attachments.first)
        @form = form_paragraph_model
        @form.attachment = form_attachment_model
        @form
      end

      def set_participatory_text
        @participatory_text = Decidim::EnhancedTextwork::ParticipatoryText.find_by(component: current_component)
      end

      def translated_paragraph_body_template
        translated_attribute component_settings.new_paragraph_body_template
      end

      def paragraph_creation_params
        params[:paragraph].merge(body_template: translated_paragraph_body_template)
      end
    end
  end
end
