# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    # This class serializes a Paragraph so can be exported to CSV, JSON or other
    # formats.
    class ParagraphSerializer < Decidim::Exporters::Serializer
      include Decidim::ApplicationHelper
      include Decidim::ResourceHelper
      include Decidim::TranslationsHelper

      # Public: Initializes the serializer with a paragraph.
      def initialize(paragraph)
        @paragraph = paragraph
      end

      # Public: Exports a hash with the serialized data for this paragraph.
      def serialize
        {
          id: paragraph.id,
          category: {
            id: paragraph.category.try(:id),
            name: paragraph.category.try(:name) || empty_translatable
          },
          scope: {
            id: paragraph.scope.try(:id),
            name: paragraph.scope.try(:name) || empty_translatable
          },
          participatory_space: {
            id: paragraph.participatory_space.id,
            url: Decidim::ResourceLocatorPresenter.new(paragraph.participatory_space).url
          },
          component: { id: component.id },
          title: paragraph.title,
          body: paragraph.body,
          state: paragraph.state.to_s,
          reference: paragraph.reference,
          answer: ensure_translatable(paragraph.answer),
          supports: paragraph.paragraph_votes_count,
          endorsements: {
            total_count: paragraph.endorsements.count,
            user_endorsements: user_endorsements
          },
          comments: paragraph.comments_count,
          attachments: paragraph.attachments.count,
          followers: paragraph.followers.count,
          published_at: paragraph.published_at,
          url: url,
          meeting_urls: meetings,
          related_paragraphs: related_paragraphs,
          is_amend: paragraph.emendation?,
          original_paragraph: {
            title: paragraph&.amendable&.title,
            url: original_paragraph_url
          }
        }
      end

      private

      attr_reader :paragraph
      alias resource paragraph

      def component
        paragraph.component
      end

      def meetings
        paragraph.linked_resources(:meetings, "paragraphs_from_meeting").map do |meeting|
          Decidim::ResourceLocatorPresenter.new(meeting).url
        end
      end

      def related_paragraphs
        paragraph.linked_resources(:paragraphs, "copied_from_component").map do |paragraph|
          Decidim::ResourceLocatorPresenter.new(paragraph).url
        end
      end

      def url
        Decidim::ResourceLocatorPresenter.new(paragraph).url
      end

      def user_endorsements
        paragraph.endorsements.for_listing.map { |identity| identity.normalized_author&.name }
      end

      def original_paragraph_url
        return unless paragraph.emendation? && paragraph.amendable.present?

        Decidim::ResourceLocatorPresenter.new(paragraph.amendable).url
      end
    end
  end
end
