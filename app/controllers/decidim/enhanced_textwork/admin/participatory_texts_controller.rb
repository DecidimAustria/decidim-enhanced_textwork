# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      # This controller manages the participatory texts area.
      class ParticipatoryTextsController < Admin::ApplicationController
        helper_method :paragraph
        helper ParticipatoryTextsHelper

        def index
          @drafts = Paragraph.where(component: current_component).drafts.order(:position)
          @preview_form = form(Admin::PreviewParticipatoryTextForm).instance
          @preview_form.from_models(@drafts)
        end

        def new_import
          enforce_permission_to :manage, :participatory_texts
          participatory_text = Decidim::EnhancedTextwork::ParticipatoryText.find_by(component: current_component)
          @import = form(Admin::ImportParticipatoryTextForm).from_model(participatory_text)
        end

        def import
          enforce_permission_to :manage, :participatory_texts
          @import = form(Admin::ImportParticipatoryTextForm).from_params(params)

          Admin::ImportParticipatoryText.call(@import) do
            on(:ok) do
              flash[:notice] = I18n.t("participatory_texts.import.success", scope: "decidim.enhanced_textwork.admin")
              redirect_to EngineRouter.admin_proxy(current_component).participatory_texts_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("participatory_texts.import.invalid", scope: "decidim.enhanced_textwork.admin")
              render action: "new_import"
            end

            on(:invalid_file) do
              flash.now[:alert] = I18n.t("participatory_texts.import.invalid_file", scope: "decidim.enhanced_textwork.admin")
              render action: "new_import"
            end
          end
        end

        def new_editor
          enforce_permission_to :manage, :participatory_texts
          participatory_text = Decidim::EnhancedTextwork::ParticipatoryText.find_by(component: current_component)
          @import = form(Admin::ImportEditorParticipatoryTextForm).from_model(participatory_text)
        end

        def import_from_editor
          enforce_permission_to :manage, :participatory_texts
          @import = form(Admin::ImportEditorParticipatoryTextForm).from_params(params)

          Admin::ImportFromEditorParticipatoryText.call(@import) do
            on(:ok) do
              flash[:notice] = I18n.t("participatory_texts.import.success", scope: "decidim.enhanced_textwork.admin")
              redirect_to EngineRouter.admin_proxy(current_component).participatory_texts_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("participatory_texts.import.invalid", scope: "decidim.enhanced_textwork.admin")
              render action: "new_editor"
            end

            on(:invalid_file) do
              flash.now[:alert] = I18n.t("participatory_texts.import.invalid_file", scope: "decidim.enhanced_textwork.admin")
              render action: "new_editor"
            end
          end
        end

        # When `save_draft` param exists, paragraphs are only saved.
        # When no `save_draft` param is set, paragraphs are saved and published.
        def update
          enforce_permission_to :manage, :participatory_texts

          form_params = params.require(:preview_participatory_text).permit!
          @preview_form = form(Admin::PreviewParticipatoryTextForm).from_params(paragraphs: form_params[:paragraphs_attributes]&.values)

          if params.has_key?("save_draft")
            UpdateParticipatoryText.call(@preview_form) do
              on(:ok) do
                flash[:notice] = I18n.t("participatory_texts.update.success", scope: "decidim.enhanced_textwork.admin")
                redirect_to EngineRouter.admin_proxy(current_component).participatory_texts_path
              end

              on(:invalid) do |failures|
                alert_msg = [I18n.t("participatory_texts.publish.invalid", scope: "decidim.enhanced_textwork.admin")]
                failures.each_pair { |id, msg| alert_msg << "ID:[#{id}] #{msg}" }
                flash.now[:alert] = alert_msg.join("<br/>").html_safe
                index
                render action: "index"
              end
            end
          else
            PublishParticipatoryText.call(@preview_form) do
              on(:ok) do
                flash[:notice] = I18n.t("participatory_texts.publish.success", scope: "decidim.enhanced_textwork.admin")
                redirect_to paragraphs_path
              end

              on(:invalid) do |failures|
                alert_msg = [I18n.t("participatory_texts.publish.invalid", scope: "decidim.enhanced_textwork.admin")]
                failures.each_pair { |id, msg| alert_msg << "ID:[#{id}] #{msg}" }
                flash.now[:alert] = alert_msg.join("<br/>").html_safe
                index
                render action: "index"
              end
            end
          end
        end

        # Removes all the unpublished paragraphs (drafts).
        def discard
          enforce_permission_to :manage, :participatory_texts

          DiscardParticipatoryText.call(current_component) do
            on(:ok) do
              flash[:notice] = I18n.t("participatory_texts.discard.success", scope: "decidim.enhanced_textwork.admin")
              redirect_to EngineRouter.admin_proxy(current_component).participatory_texts_path
            end
          end
        end
      end
    end
  end
end
