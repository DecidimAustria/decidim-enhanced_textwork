# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      class ParagraphsSplitsController < Admin::ApplicationController
        def create
          enforce_permission_to :split, :paragraphs

          @form = form(Admin::ParagraphsSplitForm).from_params(params)

          Admin::SplitParagraphs.call(@form) do
            on(:ok) do |_paragraph|
              flash[:notice] = I18n.t("paragraphs_splits.create.success", scope: "decidim.enhanced_textwork.admin")
              redirect_to EngineRouter.admin_proxy(@form.target_component).root_path
            end

            on(:invalid) do
              flash[:alert_html] = Decidim::ValidationErrorsPresenter.new(
                I18n.t("paragraphs_splits.create.invalid", scope: "decidim.enhanced_textwork.admin"),
                @form
              ).message
              redirect_to EngineRouter.admin_proxy(current_component).root_path
            end
          end
        end
      end
    end
  end
end
