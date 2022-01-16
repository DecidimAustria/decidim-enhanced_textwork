# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module AdminLog
      # This class holds the logic to present a `Decidim::EnhancedTextwork::Paragraph`
      # for the `AdminLog` log.
      #
      # Usage should be automatic and you shouldn't need to call this class
      # directly, but here's an example:
      #
      #    action_log = Decidim::ActionLog.last
      #    view_helpers # => this comes from the views
      #    ParagraphPresenter.new(action_log, view_helpers).present
      class ParagraphPresenter < Decidim::Log::BasePresenter
        private

        def resource_presenter
          @resource_presenter ||= Decidim::EnhancedTextwork::Log::ResourcePresenter.new(action_log.resource, h, action_log.extra["resource"])
        end

        def diff_fields_mapping
          {
            title: "Decidim::EnhancedTextwork::AdminLog::ValueTypes::ParagraphTitleBodyPresenter",
            body: "Decidim::EnhancedTextwork::AdminLog::ValueTypes::ParagraphTitleBodyPresenter",
            state: "Decidim::EnhancedTextwork::AdminLog::ValueTypes::ParagraphStatePresenter",
            answered_at: :date,
            answer: :i18n
          }
        end

        def action_string
          case action
          when "answer", "create", "update", "publish_answer"
            "decidim.enhanced_textwork.admin_log.paragraph.#{action}"
          else
            super
          end
        end

        def i18n_labels_scope
          "activemodel.attributes.paragraph"
        end

        def diff_actions
          super + %w(answer)
        end
      end
    end
  end
end
