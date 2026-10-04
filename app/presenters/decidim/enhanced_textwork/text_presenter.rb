# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class TextPresenter < Decidim::ResourcePresenter
      def title(html_escape: false, all_locales: false)
        super(__getobj__.title, html_escape, all_locales)
      end

      def body(links: false, strip_tags: false, all_locales: false)
        content_handle_locale(__getobj__.body, all_locales, links, strip_tags)
      end
    end
  end
end
