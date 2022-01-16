# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      class ValuationAssignmentsController < Admin::ApplicationController
        def create
          enforce_permission_to :assign_to_valuator, :paragraphs

          @form = form(Admin::ValuationAssignmentForm).from_params(params)

          Admin::AssignParagraphsToValuator.call(@form) do
            on(:ok) do |_paragraph|
              flash[:notice] = I18n.t("valuation_assignments.create.success", scope: "decidim.enhanced_textwork.admin")
              redirect_to EngineRouter.admin_proxy(current_component).root_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("valuation_assignments.create.invalid", scope: "decidim.enhanced_textwork.admin")
              redirect_to EngineRouter.admin_proxy(current_component).root_path
            end
          end
        end

        def destroy
          @form = form(Admin::ValuationAssignmentForm).from_params(destroy_params)

          enforce_permission_to :unassign_from_valuator, :paragraphs, valuator: @form.valuator_user

          Admin::UnassignParagraphsFromValuator.call(@form) do
            on(:ok) do |_paragraph|
              flash.keep[:notice] = I18n.t("valuation_assignments.delete.success", scope: "decidim.enhanced_textwork.admin")
              redirect_back fallback_location: EngineRouter.admin_proxy(current_component).root_path
            end

            on(:invalid) do
              flash.keep[:alert] = I18n.t("valuation_assignments.delete.invalid", scope: "decidim.enhanced_textwork.admin")
              redirect_back fallback_location: EngineRouter.admin_proxy(current_component).root_path
            end
          end
        end

        private

        def destroy_params
          {
            id: params.dig(:valuator_role, :id) || params[:id],
            paragraph_ids: params[:paragraph_ids] || [params[:paragraph_id]]
          }
        end

        def skip_manage_component_permission
          true
        end
      end
    end
  end
end
