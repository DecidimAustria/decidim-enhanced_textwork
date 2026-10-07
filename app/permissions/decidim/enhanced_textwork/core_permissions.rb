# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class CorePermissions < Decidim::DefaultPermissions
      def permissions
        resource = context[:textwork_resource] || context[:resource] || context[:follow]&.followable
        return permission_action unless Participation.resource?(resource)

        allowed = case permission_action.subject
                  when :like then Participation.like_allowed?(user, resource, add: permission_action.action == :create)
                  when :follow then Participation.follow_allowed?(user, resource)
                  else return permission_action
                  end
        disallow! unless allowed
        permission_action
      end

      # Apply after Core, so allowed_to? can return false in Core cells without
      # throwing during rendering. The controllers' enforce_permission_to raises.
      module Global
        def permissions
          super
          CorePermissions.new(user, permission_action, context).permissions
        end
      end
    end

    module CoreFollowContext
      def permissions_context
        super.merge(textwork_resource: resource)
      end
    end

    module CoreCommentPermissions
      def comment_write? = permission_action.subject == :comment && [:create, :update, :vote].include?(permission_action.action)

      def permissions
        super
        resource = Participation.root(context[:comment] || context[:commentable])
        disallow! if Participation.resource?(resource) && comment_write? && !(resource.visible? && Participation.open?(resource.component, :comments))
        permission_action
      end
    end
  end
end
