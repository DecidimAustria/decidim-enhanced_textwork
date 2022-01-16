# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      # This controller allows admins to make private notes on paragraphs in a participatory process.
      class ParagraphNotesController < Admin::ApplicationController
        helper_method :paragraph

        def create
          enforce_permission_to :create, :paragraph_note, paragraph: paragraph
          @form = form(ParagraphNoteForm).from_params(params)

          CreateParagraphNote.call(@form, paragraph) do
            on(:ok) do
              flash[:notice] = I18n.t("paragraph_notes.create.success", scope: "decidim.enhanced_textwork.admin")
              redirect_to paragraph_path(id: paragraph.id)
            end

            on(:invalid) do
              flash.keep[:alert] = I18n.t("paragraph_notes.create.error", scope: "decidim.enhanced_textwork.admin")
              redirect_to paragraph_path(id: paragraph.id)
            end
          end
        end

        private

        def skip_manage_component_permission
          true
        end

        def paragraph
          @paragraph ||= Paragraph.where(component: current_component).find(params[:paragraph_id])
        end
      end
    end
  end
end
