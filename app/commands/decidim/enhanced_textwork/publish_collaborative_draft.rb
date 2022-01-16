# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    # A command with all the business logic when a user publishes a collaborative_draft.
    class PublishCollaborativeDraft < Rectify::Command
      # Public: Initializes the command.
      #
      # collaborative_draft - The collaborative_draft to publish.
      # current_user - The current user.
      # paragraph_form - the form object of the new paragraph
      def initialize(collaborative_draft, current_user)
        @collaborative_draft = collaborative_draft
        @current_user = current_user
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid and the collaborative_draft is published.
      # - :invalid if the collaborative_draft's author is not the current user.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) unless @collaborative_draft.open?
        return broadcast(:invalid) unless @collaborative_draft.authored_by? @current_user

        transaction do
          reject_access_to_collaborative_draft
          publish_collaborative_draft
          create_paragraph!
          link_collaborative_draft_and_paragraph
        end

        broadcast(:ok, @new_paragraph)
      end

      attr_accessor :new_paragraph

      private

      def reject_access_to_collaborative_draft
        @collaborative_draft.requesters.each do |requester_user|
          RejectAccessToCollaborativeDraft.call(@collaborative_draft, current_user, requester_user)
        end
      end

      def publish_collaborative_draft
        Decidim.traceability.update!(
          @collaborative_draft,
          @current_user,
          { state: "published", published_at: Time.current },
          visibility: "public-only"
        )
      end

      def paragraph_attributes
        fields = {}

        parsed_title = Decidim::ContentProcessor.parse_with_processor(:hashtag, @collaborative_draft.title, current_organization: @collaborative_draft.organization).rewrite
        parsed_body = Decidim::ContentProcessor.parse_with_processor(:hashtag, @collaborative_draft.body, current_organization: @collaborative_draft.organization).rewrite

        fields[:title] = { I18n.locale => parsed_title }
        fields[:body] = { I18n.locale => parsed_body }
        fields[:component] = @collaborative_draft.component
        fields[:scope] = @collaborative_draft.scope
        fields[:address] = @collaborative_draft.address
        fields[:published_at] = Time.current

        fields
      end

      def create_paragraph!
        @new_paragraph = Decidim.traceability.perform_action!(
          :create,
          Decidim::EnhancedTextwork::Paragraph,
          @current_user,
          visibility: "public-only"
        ) do
          new_paragraph = Paragraph.new(paragraph_attributes)
          new_paragraph.coauthorships = @collaborative_draft.coauthorships
          new_paragraph.category = @collaborative_draft.category
          new_paragraph.attachments = @collaborative_draft.attachments
          new_paragraph.save!
          new_paragraph
        end
      end

      def link_collaborative_draft_and_paragraph
        @collaborative_draft.link_resources(@new_paragraph, "created_from_collaborative_draft")
      end
    end
  end
end
