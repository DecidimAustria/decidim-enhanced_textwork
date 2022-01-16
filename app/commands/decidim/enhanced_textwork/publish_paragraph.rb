# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    # A command with all the business logic when a user publishes a draft paragraph.
    class PublishParagraph < Rectify::Command
      # Public: Initializes the command.
      #
      # paragraph     - The paragraph to publish.
      # current_user - The current user.
      def initialize(paragraph, current_user)
        @paragraph = paragraph
        @current_user = current_user
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid and the paragraph is published.
      # - :invalid if the paragraph's author is not the current user.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) unless @paragraph.authored_by?(@current_user)

        transaction do
          publish_paragraph
          increment_scores
          send_notification
          send_notification_to_participatory_space
        end

        broadcast(:ok, @paragraph)
      end

      private

      # This will be the PaperTrail version that is
      # shown in the version control feature (1 of 1)
      #
      # For an attribute to appear in the new version it has to be reset
      # and reassigned, as PaperTrail only keeps track of object CHANGES.
      def publish_paragraph
        title = reset(:title)
        body = reset(:body)

        Decidim.traceability.perform_action!(
          "publish",
          @paragraph,
          @current_user,
          visibility: "public-only"
        ) do
          @paragraph.update title: title, body: body, published_at: Time.current
        end
      end

      # Reset the attribute to an empty string and return the old value
      def reset(attribute)
        attribute_value = @paragraph[attribute]
        PaperTrail.request(enabled: false) do
          # rubocop:disable Rails/SkipsModelValidations
          @paragraph.update_attribute attribute, ""
          # rubocop:enable Rails/SkipsModelValidations
        end
        attribute_value
      end

      def send_notification
        return if @paragraph.coauthorships.empty?

        Decidim::EventsManager.publish(
          event: "decidim.events.enhanced_textwork.paragraph_published",
          event_class: Decidim::EnhancedTextwork::PublishParagraphEvent,
          resource: @paragraph,
          followers: coauthors_followers
        )
      end

      def send_notification_to_participatory_space
        Decidim::EventsManager.publish(
          event: "decidim.events.enhanced_textwork.paragraph_published",
          event_class: Decidim::EnhancedTextwork::PublishParagraphEvent,
          resource: @paragraph,
          followers: @paragraph.participatory_space.followers - coauthors_followers,
          extra: {
            participatory_space: true
          }
        )
      end

      def coauthors_followers
        @coauthors_followers ||= @paragraph.authors.flat_map(&:followers)
      end

      def increment_scores
        @paragraph.coauthorships.find_each do |coauthorship|
          if coauthorship.user_group
            Decidim::Gamification.increment_score(coauthorship.user_group, :paragraphs)
          else
            Decidim::Gamification.increment_score(coauthorship.author, :paragraphs)
          end
        end
      end
    end
  end
end
