# frozen_string_literal: true

module Decidim
  module ContentParsers
    # A parser that searches mentions of Paragraphs in content.
    #
    # This parser accepts two ways for linking Paragraphs.
    # - Using a standard url starting with http or https.
    # - With a word starting with `~` and digits afterwards will be considered a possible mentioned paragraph.
    # For example `~1234`, but no `~ 1234`.
    #
    # Also fills a `Metadata#linked_paragraphs` attribute.
    #
    # @see BaseParser Examples of how to use a content parser
    class ParagraphParser < BaseParser
      # Class used as a container for metadata
      #
      # @!attribute linked_paragraphs
      #   @return [Array] an array of Decidim::EnhancedTextwork::Paragraph mentioned in content
      Metadata = Struct.new(:linked_paragraphs)

      # Matches a URL
      URL_REGEX_SCHEME = '(?:http(s)?:\/\/)'
      URL_REGEX_CONTENT = '[\w.-]+[\w\-\._~:\/?#\[\]@!\$&\'\(\)\*\+,;=.]+'
      URL_REGEX_END_CHAR = '[\d]'
      URL_REGEX = %r{#{URL_REGEX_SCHEME}#{URL_REGEX_CONTENT}/paragraphs/#{URL_REGEX_END_CHAR}+}i.freeze
      # Matches a mentioned Paragraph ID (~(d)+ expression)
      ID_REGEX = /~(\d+)/.freeze

      def initialize(content, context)
        super
        @metadata = Metadata.new([])
      end

      # Replaces found mentions matching an existing
      # Paragraph with a global id for that Paragraph. Other mentions found that doesn't
      # match an existing Paragraph are returned as they are.
      #
      # @return [String] the content with the valid mentions replaced by a global id.
      def rewrite
        rewrited_content = parse_for_urls(content)
        parse_for_ids(rewrited_content)
      end

      # (see BaseParser#metadata)
      attr_reader :metadata

      private

      def parse_for_urls(content)
        content.gsub(URL_REGEX) do |match|
          paragraph = paragraph_from_url_match(match)
          if paragraph
            @metadata.linked_paragraphs << paragraph.id
            paragraph.to_global_id
          else
            match
          end
        end
      end

      def parse_for_ids(content)
        content.gsub(ID_REGEX) do |match|
          paragraph = paragraph_from_id_match(Regexp.last_match(1))
          if paragraph
            @metadata.linked_paragraphs << paragraph.id
            paragraph.to_global_id
          else
            match
          end
        end
      end

      def paragraph_from_url_match(match)
        uri = URI.parse(match)
        return if uri.path.blank?

        paragraph_id = uri.path.split("/").last
        find_paragraph_by_id(paragraph_id)
      rescue URI::InvalidURIError
        Rails.logger.error("#{e.message}=>#{e.backtrace}")
        nil
      end

      def paragraph_from_id_match(match)
        paragraph_id = match
        find_paragraph_by_id(paragraph_id)
      end

      def find_paragraph_by_id(id)
        if id.present?
          spaces = Decidim.participatory_space_manifests.flat_map do |manifest|
            manifest.participatory_spaces.call(context[:current_organization]).public_spaces
          end
          components = Component.where(participatory_space: spaces).published
          Decidim::EnhancedTextwork::Paragraph.where(component: components).find_by(id: id)
        end
      end
    end
  end
end
