# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    # A command with all the business logic when a user creates a new paragraph.
    class CreateParagraph < Rectify::Command
      include ::Decidim::AttachmentMethods
      include HashtagsMethods

      # Public: Initializes the command.
      #
      # form         - A form object with the params.
      # current_user - The current user.
      # coauthorships - The coauthorships of the paragraph.
      def initialize(form, current_user, coauthorships = nil)
        @form = form
        @current_user = current_user
        @coauthorships = coauthorships
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid, together with the paragraph.
      # - :invalid if the form wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) if form.invalid?

        if paragraph_limit_reached?
          form.errors.add(:base, I18n.t("decidim.enhanced_textwork.new.limit_reached"))
          return broadcast(:invalid)
        end

        transaction do
          create_paragraph
        end

        broadcast(:ok, paragraph)
      end

      private

      attr_reader :form, :paragraph, :attachment

      # Prevent PaperTrail from creating an additional version
      # in the paragraph multi-step creation process (step 1: create)
      #
      # A first version will be created in step 4: publish
      # for diff rendering in the paragraph version control
      def create_paragraph
        PaperTrail.request(enabled: false) do
          @paragraph = Decidim.traceability.perform_action!(
            :create,
            Decidim::EnhancedTextwork::Paragraph,
            @current_user,
            visibility: "public-only"
          ) do
            paragraph = Paragraph.new(
              title: {
                I18n.locale => title_with_hashtags
              },
              body: {
                I18n.locale => body_with_hashtags
              },
              component: form.component
            )
            paragraph.add_coauthor(@current_user, user_group: user_group)
            paragraph.save!
            paragraph
          end
        end
      end

      def paragraph_limit_reached?
        return false if @coauthorships.present?

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
        @organization ||= @current_user.organization
      end

      def current_user_paragraphs
        Paragraph.from_author(@current_user).where(component: form.current_component).except_withdrawn
      end

      def user_group_paragraphs
        Paragraph.from_user_group(@user_group).where(component: form.current_component).except_withdrawn
      end
    end
  end
end
