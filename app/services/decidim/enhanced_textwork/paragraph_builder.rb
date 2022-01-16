# frozen_string_literal: true

require "open-uri"

module Decidim
  module EnhancedTextwork
    # A factory class to ensure we always create Paragraphs the same way since it involves some logic.
    module ParagraphBuilder
      # Public: Creates a new Paragraph.
      #
      # attributes        - The Hash of attributes to create the Paragraph with.
      # author            - An Authorable the will be the first coauthor of the Paragraph.
      # user_group_author - A User Group to, optionally, set it as the author too.
      # action_user       - The User to be used as the user who is creating the paragraph in the traceability logs.
      #
      # Returns a Paragraph.
      def create(attributes:, author:, action_user:, user_group_author: nil)
        Decidim.traceability.perform_action!(:create, Paragraph, action_user, visibility: "all") do
          paragraph = Paragraph.new(attributes)
          paragraph.add_coauthor(author, user_group: user_group_author)
          paragraph.save!
          paragraph
        end
      end

      module_function :create

      # Public: Creates a new Paragraph with the authors of the `original_paragraph`.
      #
      # attributes - The Hash of attributes to create the Paragraph with.
      # action_user - The User to be used as the user who is creating the paragraph in the traceability logs.
      # original_paragraph - The paragraph from which authors will be copied.
      #
      # Returns a Paragraph.
      def create_with_authors(attributes:, action_user:, original_paragraph:)
        Decidim.traceability.perform_action!(:create, Paragraph, action_user, visibility: "all") do
          paragraph = Paragraph.new(attributes)
          original_paragraph.coauthorships.each do |coauthorship|
            paragraph.add_coauthor(coauthorship.author, user_group: coauthorship.user_group)
          end
          paragraph.save!
          paragraph
        end
      end

      module_function :create_with_authors

      # Public: Creates a new Paragraph by copying the attributes from another one.
      #
      # original_paragraph - The Paragraph to be used as base to create the new one.
      # author            - An Authorable the will be the first coauthor of the Paragraph.
      # user_group_author - A User Group to, optionally, set it as the author too.
      # action_user       - The User to be used as the user who is creating the paragraph in the traceability logs.
      # extra_attributes  - A Hash of attributes to create the new paragraph, will overwrite the original ones.
      # skip_link         - Whether to skip linking the two paragraphs or not (default false).
      #
      # Returns a Paragraph
      #
      # rubocop:disable Metrics/ParameterLists
      def copy(original_paragraph, author:, action_user:, user_group_author: nil, extra_attributes: {}, skip_link: false)
        origin_attributes = original_paragraph.attributes.except(
          "id",
          "created_at",
          "updated_at",
          "state",
          "state_published_at",
          "answer",
          "answered_at",
          "decidim_component_id",
          "reference",
          "comments_count",
          "endorsements_count",
          "follows_count",
          "paragraph_notes_count",
          "paragraph_votes_count"
        ).merge(
          "category" => original_paragraph.category
        ).merge(
          extra_attributes
        )

        paragraph = if author.nil?
                     create_with_authors(
                       attributes: origin_attributes,
                       original_paragraph: original_paragraph,
                       action_user: action_user
                     )
                   else
                     create(
                       attributes: origin_attributes,
                       author: author,
                       user_group_author: user_group_author,
                       action_user: action_user
                     )
                   end

        paragraph.link_resources(original_paragraph, "copied_from_component") unless skip_link
        copy_attachments(original_paragraph, paragraph)

        paragraph
      end
      # rubocop:enable Metrics/ParameterLists

      module_function :copy

      def copy_attachments(original_paragraph, paragraph)
        original_paragraph.attachments.each do |attachment|
          new_attachment = Decidim::Attachment.new(
            {
              # Attached to needs to be always defined before the file is set
              attached_to: paragraph
            }.merge(
              attachment.attributes.slice("content_type", "description", "file_size", "title", "weight")
            )
          )

          if attachment.file.attached?
            new_attachment.file = attachment.file.blob
          else
            new_attachment.attached_uploader(:file).remote_url = attachment.attached_uploader(:file).url(host: original_paragraph.organization.host)
          end

          new_attachment.save!
        rescue Errno::ENOENT, OpenURI::HTTPError => e
          Rails.logger.warn("[ERROR] Couldn't copy attachment from paragraph #{original_paragraph.id} when copying to component due to #{e.message}")
        end
      end

      module_function :copy_attachments
    end
  end
end
