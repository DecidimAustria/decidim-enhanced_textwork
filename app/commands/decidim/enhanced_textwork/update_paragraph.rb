# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    # A command with all the business logic when a user updates a paragraph.
    class UpdateParagraph < Rectify::Command
      include ::Decidim::MultipleAttachmentsMethods
      include GalleryMethods
      include HashtagsMethods

      # Public: Initializes the command.
      #
      # form         - A form object with the params.
      # current_user - The current user.
      # paragraph - the paragraph to update.
      def initialize(form, current_user, paragraph)
        @form = form
        @current_user = current_user
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
        return broadcast(:invalid) if invalid?

        if process_attachments?
          build_attachments
          return broadcast(:invalid) if attachments_invalid?
        end

        if process_gallery?
          build_gallery
          return broadcast(:invalid) if gallery_invalid?
        end

        transaction do
          if @paragraph.draft?
            update_draft
          else
            update_paragraph
          end
          create_gallery if process_gallery?
          create_attachments if process_attachments?

          photo_cleanup!
          document_cleanup!
        end

        broadcast(:ok, paragraph)
      end

      private

      attr_reader :form, :paragraph, :current_user, :attachment

      def invalid?
        form.invalid? || !paragraph.editable_by?(current_user) || paragraph_limit_reached?
      end

      # Prevent PaperTrail from creating an additional version
      # in the paragraph multi-step creation process (step 3: complete)
      #
      # A first version will be created in step 4: publish
      # for diff rendering in the paragraph control version
      def update_draft
        PaperTrail.request(enabled: false) do
          @paragraph.update(attributes)
          @paragraph.coauthorships.clear
          @paragraph.add_coauthor(current_user, user_group: user_group)
        end
      end

      def update_paragraph
        @paragraph = Decidim.traceability.update!(
          @paragraph,
          current_user,
          attributes,
          visibility: "public-only"
        )
        @paragraph.coauthorships.clear
        @paragraph.add_coauthor(current_user, user_group: user_group)
      end

      def attributes
        {
          title: {
            I18n.locale => title_with_hashtags
          },
          body: {
            I18n.locale => body_with_hashtags
          },
          category: form.category,
          scope: form.scope,
          address: form.address,
          latitude: form.latitude,
          longitude: form.longitude
        }
      end

      def paragraph_limit_reached?
        paragraph_limit = form.current_component.settings.paragraph_limit

        return false if paragraph_limit.zero?

        if user_group
          user_group_paragraphs.count >= paragraph_limit
        else
          current_user_paragraphs.count >= paragraph_limit
        end
      end

      def user_group
        @user_group ||= Decidim::UserGroup.find_by(organization: organization, id: form.user_group_id)
      end

      def organization
        @organization ||= current_user.organization
      end

      def current_user_paragraphs
        Paragraph.from_author(current_user).where(component: form.current_component).published.where.not(id: paragraph.id).except_withdrawn
      end

      def user_group_paragraphs
        Paragraph.from_user_group(user_group).where(component: form.current_component).published.where.not(id: paragraph.id).except_withdrawn
      end
    end
  end
end
