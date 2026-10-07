# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class Permissions < Decidim::DefaultPermissions
      def permissions
        return permission_action unless permission_action.subject == :textwork

        component = context[:current_component]
        allowed = permission_action.scope == :admin && Access.admin?(user, component)
        document = context[:document]
        allowed &&= case permission_action.action
                    when :manage then true
                    when :edit_original then document&.component == component && document.original_editable?
                    when :withdraw then document&.component == component && document.withdrawable?
                    when :evaluate then document&.component == component && Access.evaluation_allowed?(user, document)
                    else false
                    end
        toggle_allow(allowed)
        permission_action
      end
    end
  end
end
