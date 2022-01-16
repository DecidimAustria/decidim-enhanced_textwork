# frozen_string_literal: true

require "kramdown"

module Decidim
  module EnhancedTextwork
    # This class parses a participatory text document from quill editor in markdown
    #
    # This implementation uses Kramdown Base renderer.
    #
    class HtmlToMarkdown
      # Public: Initializes the serializer with a paragraph.
      def initialize(html)
        @html = html
      end

      def to_md
        ::Kramdown::Document.new(@html, input: "html").to_kramdown
      end
    end
  end
end
