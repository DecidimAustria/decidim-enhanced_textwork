# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class Permissions < Decidim::DefaultPermissions
      def permissions
        return permission_action unless permission_action.subject == :textwork

        component = context[:current_component]
        toggle_allow(permission_action.scope == :admin && Access.admin?(user, component))
        permission_action
      end
    end
  end
end
