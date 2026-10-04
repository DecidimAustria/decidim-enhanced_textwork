# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class DecideAmendment
      class Conflict < StandardError; end

      def self.call(amendment, user, state, reason)
        raise Decidim::ActionForbidden unless Access.admin?(user, amendment.component)
        raise ArgumentError unless %w(accepted rejected).include?(state)

        amendment.document.with_lock do
          amendment.lock!
          raise Conflict unless amendment.state == "pending" && amendment.visible?

          section = amendment.section
          section.lock!
          if state == "accepted"
            raise Conflict if amendment.stale?

            revision = section.revisions.create!(author: user, number: section.revisions.maximum(:number) + 1,
                                                 title: amendment.title, body: amendment.body)
            section.update!(current_revision: revision)
            amendment.result_revision = revision
            amendment.document.snapshot!(user)
          end
          Decidim.traceability.perform_action!(state, amendment, user) do
            amendment.update!(state:, decision_reason: reason, decided_by: user, decided_at: Time.current)
          end
        end
        Decidim::EventsManager.publish(event: "decidim.events.enhanced_textwork.amendment_decided",
                                       event_class: AmendmentDecidedEvent, resource: amendment, affected_users: [amendment.author])
      end
    end
  end
end
