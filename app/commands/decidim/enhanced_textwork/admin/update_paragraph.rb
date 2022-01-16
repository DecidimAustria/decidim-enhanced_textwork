# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      # A command with all the business logic when a user updates a paragraph.
      class UpdateParagraph < Rectify::Command
        include ::Decidim::AttachmentMethods
        include GalleryMethods
        include HashtagsMethods

        # Public: Initializes the command.
        #
        # form         - A form object with the params.
        # paragraph - the paragraph to update.
        def initialize(form, paragraph)
          @form = form
          @paragraph = paragraph
          @attached_to = paragraph
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid, together with the paragraph.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if form.invalid?

          delete_attachment(form.attachment) if delete_attachment?

          if process_attachments?
            @paragraph.attachments.destroy_all

            build_attachment
            return broadcast(:invalid) if attachment_invalid?
          end

          if process_gallery?
            build_gallery
            return broadcast(:invalid) if gallery_invalid?
          end

          transaction do
            update_paragraph
            update_paragraph_author
            create_attachment if process_attachments?
            create_gallery if process_gallery?
            photo_cleanup!
          end

          broadcast(:ok, paragraph)
        end

        private

        attr_reader :form, :paragraph, :attachment, :gallery

        def update_paragraph
          parsed_title = Decidim::ContentProcessor.parse_with_processor(:hashtag, form.title, current_organization: form.current_organization).rewrite
          parsed_body = Decidim::ContentProcessor.parse_with_processor(:hashtag, form.body, current_organization: form.current_organization).rewrite
          Decidim.traceability.update!(
            paragraph,
            form.current_user,
            title: parsed_title,
            body: parsed_body,
            category: form.category,
            scope: form.scope,
            address: form.address,
            latitude: form.latitude,
            longitude: form.longitude,
            created_in_meeting: form.created_in_meeting
          )
        end

        def update_paragraph_author
          paragraph.coauthorships.clear
          paragraph.add_coauthor(form.author)
          paragraph.save!
          paragraph
        end
      end
    end
  end
end
