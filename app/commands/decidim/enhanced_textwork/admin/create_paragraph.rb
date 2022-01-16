# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      # A command with all the business logic when a user creates a new paragraph.
      class CreateParagraph < Rectify::Command
        include ::Decidim::AttachmentMethods
        include GalleryMethods
        include HashtagsMethods

        # Public: Initializes the command.
        #
        # form - A form object with the params.
        def initialize(form)
          @form = form
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid, together with the paragraph.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if form.invalid?

          if process_attachments?
            build_attachment
            return broadcast(:invalid) if attachment_invalid?
          end

          if process_gallery?
            build_gallery
            return broadcast(:invalid) if gallery_invalid?
          end

          transaction do
            create_paragraph
            create_attachment if process_attachments?
            create_gallery if process_gallery?
            link_author_meeeting if form.created_in_meeting?
            send_notification
          end

          broadcast(:ok, paragraph)
        end

        private

        attr_reader :form, :paragraph, :attachment, :gallery

        def create_paragraph
          @paragraph = Decidim::EnhancedTextwork::ParagraphBuilder.create(
            attributes: attributes,
            author: form.author,
            action_user: form.current_user
          )
          @attached_to = @paragraph
        end

        def attributes
          parsed_title = Decidim::ContentProcessor.parse_with_processor(:hashtag, form.title, current_organization: form.current_organization).rewrite
          parsed_body = Decidim::ContentProcessor.parse_with_processor(:hashtag, form.body, current_organization: form.current_organization).rewrite
          {
            title: parsed_title,
            body: parsed_body,
            category: form.category,
            scope: form.scope,
            component: form.component,
            address: form.address,
            latitude: form.latitude,
            longitude: form.longitude,
            created_in_meeting: form.created_in_meeting,
            published_at: Time.current
          }
        end

        def link_author_meeeting
          paragraph.link_resources(form.author, "paragraphs_from_meeting")
        end

        def send_notification
          Decidim::EventsManager.publish(
            event: "decidim.events.enhanced_textwork.paragraph_published",
            event_class: Decidim::EnhancedTextwork::PublishParagraphEvent,
            resource: paragraph,
            followers: @paragraph.participatory_space.followers,
            extra: {
              participatory_space: true
            }
          )
        end
      end
    end
  end
end
