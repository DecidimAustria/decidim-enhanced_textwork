# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    # Simple helper to handle markup variations for participatory texts related partials
    module ParticipatoryTextsHelper
      # Returns the title for a given participatory text section.
      #
      # paragraph - The current paragraph item.
      #
      # Returns a string with the title of the section, subsection or article.
      def preview_participatory_text_section_title(paragraph)
        title = decidim_html_escape(present(paragraph).title)
        translated = t(paragraph.participatory_text_level, scope: "decidim.enhanced_textwork.admin.participatory_texts.sections", title: title)
        translated.html_safe
      end

      def render_participatory_text_title(participatory_text)
        if participatory_text.nil?
          t("alternative_title", scope: "decidim.enhanced_textwork.participatory_text_paragraph")
        else
          translated_attribute(participatory_text.title)
        end
      end

      # Public: A formatted collection of mime_type to be used
      # in forms.
      def mime_types_with_document_examples
        links = ""
        accepted_mime_types = Decidim::EnhancedTextwork::DocToMarkdown::ACCEPTED_MIME_TYPES.keys
        accepted_mime_types.each_with_index do |mime_type, index|
          links += link_to t(".accepted_mime_types.#{mime_type}"),
                           asset_pack_path("media/documents/participatory_text.#{mime_type}"),
                           download: "participatory_text.#{mime_type}"
          links += ", " unless accepted_mime_types.length == index + 1
        end
        links
      end

      def show_paragraph_title?(paragraph)
        !hide_paragraph_title?(paragraph)
      end

      def hide_paragraph_title?(paragraph)
        paragraph.component.settings.hide_participatory_text_titles_enabled? && translated_attribute(paragraph.title) !~ /\D/
      end
    end
  end
end
