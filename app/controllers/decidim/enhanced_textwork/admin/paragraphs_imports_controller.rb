# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      class ParagraphsImportsController < Admin::ApplicationController
        def new
          enforce_permission_to :import, :paragraphs

          @form = form(Admin::ParagraphsImportForm).instance
        end

        def create
          enforce_permission_to :import, :paragraphs

          @form = form(Admin::ParagraphsImportForm).from_params(params)

          Admin::ImportParagraphs.call(@form) do
            on(:ok) do |paragraphs|
              flash[:notice] = I18n.t("paragraphs_imports.create.success", scope: "decidim.enhanced_textwork.admin", number: paragraphs.length)
              redirect_to EngineRouter.admin_proxy(current_component).root_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("paragraphs_imports.create.invalid", scope: "decidim.enhanced_textwork.admin")
              render action: "new"
            end
          end
        end
      end
    end
  end
end
