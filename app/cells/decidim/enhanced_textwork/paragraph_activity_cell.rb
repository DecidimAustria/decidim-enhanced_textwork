# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    # A cell to display when actions happen on a paragraph.
    class ParagraphActivityCell < ActivityCell
      def title
        case action
        when "update"
          I18n.t(
            "decidim.enhanced_textwork.last_activity.paragraph_updated_at_html",
            link: participatory_space_link
          )
        else
          I18n.t(
            "decidim.enhanced_textwork.last_activity.new_paragraph_at_html",
            link: participatory_space_link
          )
        end
      end

      def resource_link_text
        decidim_html_escape(presenter.title)
      end

      def description
        strip_tags(presenter.body(links: true))
      end

      def presenter
        @presenter ||= Decidim::EnhancedTextwork::ParagraphPresenter.new(resource)
      end
    end
  end
end
