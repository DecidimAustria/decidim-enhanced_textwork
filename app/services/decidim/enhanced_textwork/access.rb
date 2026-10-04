# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Access
      def self.admin?(user, component)
        return false unless user && component && user.organization == component.organization
        return true if user.admin?

        space = component.participatory_space
        space.respond_to?(:user_roles) && space.user_roles(:admin).where(user:).exists?
      end

      def self.allowed?(user, resource, action)
        return false unless user && user.organization == resource.organization && resource.visible?
        return false unless resource.can_participate?(user)

        Decidim::ActionAuthorizer.new(user, action.to_s, resource.component, resource).authorize.ok?
      end
    end
  end
end
