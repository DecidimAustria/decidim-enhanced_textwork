# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Access
      def self.admin?(user, component)
        return false unless user && component && user.organization == component.organization
        return true if user.admin?

        space = component.participatory_space
        space.respond_to?(:user_roles) && space.user_roles(:admin).exists?(user:)
      end

      def self.allowed?(user, resource, action)
        return false unless user && user.organization == resource.organization && resource.visible?
        return false unless resource.can_participate?(user)

        Decidim::ActionAuthorizer.new(user, action.to_s, resource.component, resource).authorize.ok?
      end

      def self.evaluation_enabled?(component) = component.settings.evaluation_enabled?

      # The switch does not override collection immutability. A future evaluation
      # workflow needs its own explicit policy before it can change a document.
      def self.evaluation_allowed?(user, document)
        admin?(user, document.component) && evaluation_enabled?(document.component) && document.original_editable?
      end
    end
  end
end
