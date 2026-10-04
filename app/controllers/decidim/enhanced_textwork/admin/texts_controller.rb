# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      class TextsController < Decidim::Proposals::Admin::ApplicationController
        before_action :authorize_textwork

        def show
          @form = form(ImportForm).from_model(document)
          @drafts = draft_paragraphs.order(:position, :id)
        end

        def import
          @form = form(ImportForm).from_params(params)
          ImportText.call(@form) do
            on(:ok) do
              flash[:notice] = t("decidim.enhanced_textwork.admin.imported")
              redirect_to proposal_admin.participatory_texts_path
            end
            on(:invalid) do
              @drafts = draft_paragraphs.order(:position, :id)
              render :show, status: :unprocessable_content
            end
          end
        end

        def destroy_draft
          paragraph = draft_paragraphs.find(params[:id])
          Decidim.traceability.perform_action!(:delete, paragraph, current_user) { paragraph.destroy! }
          redirect_to proposal_admin.textwork_path, notice: t("decidim.enhanced_textwork.admin.draft_deleted")
        end

        def export
          enforce_permission_to :export, :proposals
          data = Decidim::EnhancedTextwork::DocumentExport.new(current_component, current_user, I18n.locale).export
          send_data data, filename: "textwork-#{current_component.id}-#{I18n.locale}.docx",
                          type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        end

        private

        def authorize_textwork
          raise ActionController::RoutingError, "Not Found" unless Decidim::EnhancedTextwork.enabled?(current_component)

          enforce_permission_to :manage, :participatory_texts
        end

        def document
          Decidim::Proposals::ParticipatoryText.find_by(component: current_component)
        end

        def draft_paragraphs
          Decidim::Proposals::Proposal.where(component: current_component).drafts.only_amendables
        end

        def proposal_admin
          Decidim::EngineRouter.admin_proxy(current_component)
        end
      end
    end
  end
end
