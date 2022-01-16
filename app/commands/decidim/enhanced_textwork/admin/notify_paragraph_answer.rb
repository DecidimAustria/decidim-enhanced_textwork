# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      # A command to notify about the change of the published state for a paragraph.
      class NotifyParagraphAnswer < Rectify::Command
        # Public: Initializes the command.
        #
        # paragraph - The paragraph to write the answer for.
        # initial_state - The paragraph state before the current process.
        def initialize(paragraph, initial_state)
          @paragraph = paragraph
          @initial_state = initial_state.to_s
        end

        # Executes the command. Broadcasts these events:
        #
        # - :noop when the answer is not published or the state didn't changed.
        # - :ok when everything is valid.
        #
        # Returns nothing.
        def call
          if paragraph.published_state? && state_changed?
            transaction do
              increment_score
              notify_followers
            end
          end

          broadcast(:ok)
        end

        private

        attr_reader :paragraph, :initial_state

        def state_changed?
          initial_state != paragraph.state.to_s
        end

        def notify_followers
          if paragraph.accepted?
            publish_event(
              "decidim.events.enhanced_textwork.paragraph_accepted",
              Decidim::EnhancedTextwork::AcceptedParagraphEvent
            )
          elsif paragraph.rejected?
            publish_event(
              "decidim.events.enhanced_textwork.paragraph_rejected",
              Decidim::EnhancedTextwork::RejectedParagraphEvent
            )
          elsif paragraph.evaluating?
            publish_event(
              "decidim.events.enhanced_textwork.paragraph_evaluating",
              Decidim::EnhancedTextwork::EvaluatingParagraphEvent
            )
          end
        end

        def publish_event(event, event_class)
          Decidim::EventsManager.publish(
            event: event,
            event_class: event_class,
            resource: paragraph,
            affected_users: paragraph.notifiable_identities,
            followers: paragraph.followers - paragraph.notifiable_identities
          )
        end

        def increment_score
          if paragraph.accepted?
            paragraph.coauthorships.find_each do |coauthorship|
              Decidim::Gamification.increment_score(coauthorship.user_group || coauthorship.author, :accepted_paragraphs)
            end
          elsif initial_state == "accepted"
            paragraph.coauthorships.find_each do |coauthorship|
              Decidim::Gamification.decrement_score(coauthorship.user_group || coauthorship.author, :accepted_paragraphs)
            end
          end
        end
      end
    end
  end
end
