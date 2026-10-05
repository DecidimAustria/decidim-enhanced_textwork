# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Notifications
      def self.deliver(event, resource, recipients, actor)
        users = recipients.compact.uniq.reject { |user| user == actor }
        return if users.empty?

        # Rails 7.2 defers delivery until the outer transaction commits.
        ActiveRecord.after_all_transactions_commit do
          Decidim::EventsManager.publish(event: "decidim.events.textwork.#{event}", event_class: ChangeEvent,
                                         resource:, affected_users: users, extra: { actor_id: actor.id })
        end
      end
    end
  end
end
