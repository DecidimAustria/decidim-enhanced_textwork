# frozen_string_literal: true

require "decidim/enhanced_textwork/admin"
require "decidim/enhanced_textwork/api"
require "decidim/enhanced_textwork/engine"
require "decidim/enhanced_textwork/admin_engine"
require "decidim/enhanced_textwork/component"

module Decidim
  # This namespace holds the logic of the `Paragraphs` component. This component
  # allows users to create paragraphs in a participatory process.
  module EnhancedTextwork
    autoload :ParagraphSerializer, "decidim/enhanced_textwork/paragraph_serializer"
    autoload :ParagraphCreator, "decidim/enhanced_textwork/paragraph_creator"
    autoload :CommentableParagraph, "decidim/enhanced_textwork/commentable_paragraph"
    autoload :CommentableCollaborativeDraft, "decidim/enhanced_textwork/commentable_collaborative_draft"
    autoload :MarkdownToParagraphs, "decidim/enhanced_textwork/markdown_to_paragraphs"
    autoload :ParticipatoryTextSection, "decidim/enhanced_textwork/participatory_text_section"
    autoload :DocToMarkdown, "decidim/enhanced_textwork/doc_to_markdown"
    autoload :OdtToMarkdown, "decidim/enhanced_textwork/odt_to_markdown"
    autoload :HtmlToMarkdown, "decidim/enhanced_textwork/html_to_markdown"
    autoload :Valuatable, "decidim/enhanced_textwork/valuatable"

    include ActiveSupport::Configurable

    # Public Setting that defines the similarity minimum value to consider two
    # paragraphs similar. Defaults to 0.25.
    config_accessor :similarity_threshold do
      0.25
    end

    # Public Setting that defines how many similar paragraphs will be shown.
    # Defaults to 10.
    config_accessor :similarity_limit do
      10
    end

    # Public Setting that defines how many paragraphs will be shown in the
    # participatory_space_highlighted_elements view hook
    config_accessor :participatory_space_highlighted_paragraphs_limit do
      4
    end

    # Public Setting that defines how many paragraphs will be shown in the
    # process_group_highlighted_elements view hook
    config_accessor :process_group_highlighted_paragraphs_limit do
      3
    end
  end

  module ContentParsers
    autoload :ParagraphParser, "decidim/content_parsers/paragraph_parser"
  end

  module ContentRenderers
    autoload :ParagraphRenderer, "decidim/content_renderers/paragraph_renderer"
  end
end
