# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module TextsHelper
      # Core vote partials use these unqualified helpers. Keep the complete
      # participatory-space/component mount path when rendering from our engine.
      def proposal_path(...)
        Decidim::EngineRouter.main_proxy(current_component).proposal_path(...)
      end

      def proposal_proposal_vote_path(...)
        Decidim::EngineRouter.main_proxy(current_component).proposal_proposal_vote_path(...)
      end

      def textwork_title(paragraph)
        title = translated_attribute(paragraph.title).to_s
        return title unless component_settings.textwork_hide_numbered_titles? && title.match?(/\A\s*\d+\s*\z/)

        nil
      end

      def textwork_paragraph_label(paragraph)
        textwork_title(paragraph).presence || t("decidim.enhanced_textwork.texts.paragraph", number: translated_attribute(paragraph.title))
      end

      def textwork_excerpt(paragraph, length: 100)
        text = Nokogiri::HTML.fragment(present(paragraph).body).text.squish
        truncate(text, length:, separator: " ")
      end

      def textwork_paragraph_path(paragraph, anchor: "textwork-discussion")
        Decidim::EngineRouter.main_proxy(current_component).textwork_path(paragraph_id: paragraph.id, anchor:)
      end

      def textwork_amendment_path(paragraph)
        decidim.new_amend_path(amendable_gid: paragraph.to_sgid.to_s)
      end
    end
  end
end
