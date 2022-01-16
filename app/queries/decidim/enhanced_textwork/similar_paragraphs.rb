# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    # Class used to retrieve similar paragraphs.
    class SimilarParagraphs < Rectify::Query
      include Decidim::TranslationsHelper

      # Syntactic sugar to initialize the class and return the queried objects.
      #
      # components - Decidim::CurrentComponent
      # paragraph - Decidim::EnhancedTextwork::Paragraph
      def self.for(components, paragraph)
        new(components, paragraph).query
      end

      # Initializes the class.
      #
      # components - Decidim::CurrentComponent
      # paragraph - Decidim::EnhancedTextwork::Paragraph
      def initialize(components, paragraph)
        @components = components
        @paragraph = paragraph
        @translations_enabled = paragraph.component.organization.enable_machine_translations
      end

      # Retrieves similar paragraphs
      def query
        Decidim::EnhancedTextwork::Paragraph
          .where(component: @components)
          .published
          .not_hidden
          .where(
            "GREATEST(#{title_similarity}, #{body_similarity}) >= ?",
            *similarity_params,
            Decidim::EnhancedTextwork.similarity_threshold
          )
          .limit(Decidim::EnhancedTextwork.similarity_limit)
      end

      private

      attr_reader :translations_enabled, :paragraph

      def title_similarity
        return "similarity(title::text, ?)" unless translations_enabled

        language = paragraph.content_original_language
        "similarity(title->>'#{language}'::text, ?), similarity(title->'machine_translations'->>'#{language}'::text, ?)"
      end

      def body_similarity
        return "similarity(body::text, ?)" unless translations_enabled

        language = paragraph.content_original_language
        "similarity(body->>'#{language}'::text, ?), similarity(body->'machine_translations'->>'#{language}'::text, ?)"
      end

      def similarity_params
        title_attr = translated_attribute(paragraph.title)
        body_attr = translated_attribute(paragraph.body)

        translations_enabled ? [title_attr, title_attr, body_attr, body_attr] : [title_attr, body_attr]
      end
    end
  end
end
