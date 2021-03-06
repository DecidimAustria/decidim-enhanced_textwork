# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    # A command with all the business logic when a user requests access
    # to edit a collaborative draft.
    class RequestAccessToCollaborativeDraft < Rectify::Command
      # Public: Initializes the command.
      #
      # form         - A form object with the params.
      # collaborative_draft     - A Decidim::EnhancedTextwork::CollaborativeDraft object.
      # current_user - The current user and requester user
      def initialize(form, current_user)
        @form = form
        @collaborative_draft = form.collaborative_draft
        @current_user = current_user
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid.
      # - :invalid if it wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) if @form.invalid?
        return broadcast(:invalid) if @current_user.nil?

        @collaborative_draft.collaborator_requests.create!(user: @current_user)
        notify_collaborative_draft_authors
        broadcast(:ok, @collaborative_draft)
      end

      private

      def notify_collaborative_draft_authors
        Decidim::EventsManager.publish(
          event: "decidim.events.enhanced_textwork.collaborative_draft_access_requested",
          event_class: Decidim::EnhancedTextwork::CollaborativeDraftAccessRequestedEvent,
          resource: @collaborative_draft,
          affected_users: @collaborative_draft.authors,
          extra: {
            requester_id: @current_user.id
          }
        )
      end
    end
  end
end
