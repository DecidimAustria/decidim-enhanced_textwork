# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module ContentBlocks
      class HighlightedParagraphsCell < Decidim::ContentBlocks::HighlightedElementsCell
        def base_relation
          @base_relation ||= Decidim::EnhancedTextwork::Paragraph.published.not_hidden.except_withdrawn.where(component: published_components)
        end

        private

        def limit
          Decidim::EnhancedTextwork.config.process_group_highlighted_paragraphs_limit
        end
      end
    end
  end
end
