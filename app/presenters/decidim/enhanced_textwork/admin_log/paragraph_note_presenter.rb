# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module AdminLog
      # This class holds the logic to present a `Decidim::EnhancedTextwork::ParagraphNote`
      # for the `AdminLog` log.
      #
      # Usage should be automatic and you shouldn't need to call this class
      # directly, but here's an example:
      #
      #    action_log = Decidim::ActionLog.last
      #    view_helpers # => this comes from the views
      #    ParagraphNotePresenter.new(action_log, view_helpers).present
      class ParagraphNotePresenter < Decidim::Log::BasePresenter
        private

        def diff_fields_mapping
          {
            body: :string
          }
        end

        def action_string
          case action
          when "create"
            "decidim.enhanced_textwork.admin_log.paragraph_note.#{action}"
          else
            super
          end
        end

        def i18n_labels_scope
          "activemodel.attributes.paragraph_note"
        end
      end
    end
  end
end
