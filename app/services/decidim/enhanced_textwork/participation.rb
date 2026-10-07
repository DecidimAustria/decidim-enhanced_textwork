# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Participation
      def self.resource?(resource) = resource.is_a?(Document) || resource.is_a?(Block) || resource.is_a?(Suggestion)

      def self.root(resource)
        resource = resource.root_commentable while resource.is_a?(Decidim::Comments::Comment)
        resource
      end

      def self.deadline(component)
        space = component.participatory_space
        space.active_step&.end_date if space.allows_steps? && space.respond_to?(:active_step)
      end

      def self.expired?(component)
        date = deadline(component)
        date && Time.current.in_time_zone(component.organization.time_zone).to_date > date
      end

      def self.open?(component, kind)
        return false if expired?(component)
        return false if component.current_settings.public_send("#{kind}_blocked")
        return component.settings.comments_enabled? if kind == :comments
        return component.settings.likes_enabled? && component.current_settings.likes_enabled? if kind == :likes

        true
      end

      def self.closed?(component) = [:comments, :likes, :suggestions].none? { |kind| open?(component, kind) }

      def self.like_allowed?(user, resource, add:)
        return false unless resource.respond_to?(:likeable?) && resource.likeable? && open?(resource.component, :likes)
        return false unless Access.allowed?(user, resource, :like)
        return true unless resource.is_a?(Suggestion) && resource.authored_by?(user)

        !add && resource.liked_by?(user)
      end

      def self.follow_allowed?(user, resource)
        resource.is_a?(Document) && resource.followable? && user && user.organization == resource.organization && resource.can_participate?(user)
      end
    end
  end
end
