# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module AdminLog
      # This class holds the logic to present a `Decidim::EnhancedTextwork::ValuationAssignment`
      # for the `AdminLog` log.
      #
      # Usage should be automatic and you shouldn't need to call this class
      # directly, but here's an example:
      #
      #    action_log = Decidim::ActionLog.last
      #    view_helpers # => this comes from the views
      #    ValuationAssignmentPresenter.new(action_log, view_helpers).present
      class ValuationAssignmentPresenter < Decidim::Log::BasePresenter
        private

        def resource_presenter
          @resource_presenter ||= Decidim::EnhancedTextwork::Log::ValuationAssignmentPresenter.new(action_log.resource, h, action_log.extra["resource"])
        end

        def diff_fields_mapping
          {
            valuator_role_id: "Decidim::EnhancedTextwork::AdminLog::ValueTypes::ValuatorRoleUserPresenter"
          }
        end

        def action_string
          case action
          when "create", "delete"
            "decidim.enhanced_textwork.admin_log.valuation_assignment.#{action}"
          else
            super
          end
        end

        def i18n_labels_scope
          "activemodel.attributes.valuation_assignment.admin_log"
        end

        def diff_actions
          super + %w(create delete)
        end

        def i18n_params
          super.merge(paragraph_title: h.translated_attribute(action_log.extra["paragraph_title"]))
        end
      end
    end
  end
end
