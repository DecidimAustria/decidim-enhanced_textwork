# frozen_string_literal: true

module Decidim
  module ContentRenderers
    # A renderer that searches Global IDs representing paragraphs in content
    # and replaces it with a link to their show page.
    #
    # e.g. gid://<APP_NAME>/Decidim::EnhancedTextwork::Paragraph/1
    #
    # @see BaseRenderer Examples of how to use a content renderer
    class ParagraphRenderer < BaseRenderer
      # Matches a global id representing a Decidim::User
      GLOBAL_ID_REGEX = %r{gid://([\w-]*/Decidim::EnhancedTextwork::Paragraph/(\d+))}i.freeze

      # Replaces found Global IDs matching an existing paragraph with
      # a link to its show page. The Global IDs representing an
      # invalid Decidim::EnhancedTextwork::Paragraph are replaced with '???' string.
      #
      # @return [String] the content ready to display (contains HTML)
      def render(_options = nil)
        return content unless content.respond_to?(:gsub)

        content.gsub(GLOBAL_ID_REGEX) do |paragraph_gid|
          paragraph = GlobalID::Locator.locate(paragraph_gid)
          Decidim::EnhancedTextwork::ParagraphPresenter.new(paragraph).display_mention
        rescue ActiveRecord::RecordNotFound
          paragraph_id = paragraph_gid.split("/").last
          "~#{paragraph_id}"
        end
      end
    end
  end
end
