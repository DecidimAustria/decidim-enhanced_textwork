# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      class TextsController < ApplicationController
        def show
          @document = Document.find_by(component: current_component)
          @form = form(ImportForm).from_model(@document)
          @drafts = @document ? @document.sections.includes(:current_revision) : Section.none
        end

        def import
          @form = form(ImportForm).from_params(params)
          ImportText.call(@form) do
            on(:ok) { redirect_to textwork_path, notice: t("decidim.enhanced_textwork.admin.imported") }
            on(:invalid) do
              @document = Document.find_by(component: current_component)
              @drafts = @document ? @document.sections : Section.none
              render :show, status: :unprocessable_content
            end
          end
        end

        def publish
          document.with_lock do
            if !document.published? && document.sections.any?
              document.update!(published_at: Time.current)
              document.snapshot!(current_user)
            end
          end
          redirect_to textwork_path
        end

        def export
          data = DocumentExport.new(current_component, current_user, I18n.locale).export
          send_data data, filename: "textwork-#{current_component.id}-#{I18n.locale}.docx",
                          type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        end
      end
    end
  end
end
