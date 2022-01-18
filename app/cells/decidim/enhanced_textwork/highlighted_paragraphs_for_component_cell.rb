# frozen_string_literal: true

require "cell/partial"

module Decidim
  module EnhancedTextwork
    # This cell renders the highlighted paragraphs for a given component.
    # It is intended to be used in the `participatory_space_highlighted_elements`
    # view hook.
    class HighlightedParagraphsForComponentCell < Decidim::ViewModel
      include Decidim::ComponentPathHelper

      def show
        render unless paragraphs_count.zero?
      end

      private

      def paragraphs
        @paragraphs ||= if model.settings.participatory_texts_enabled?
                         Decidim::EnhancedTextwork::Paragraph.published.not_hidden.except_withdrawn
                                                    .only_emendations
                                                    .where(component: model)
                                                    .order_randomly(rand * 2 - 1)
                       else
                         Decidim::EnhancedTextwork::Paragraph.published.not_hidden.except_withdrawn
                                                    .where(component: model)
                                                    .order_randomly(rand * 2 - 1)
                       end
      end

      def paragraphs_to_render
        @paragraphs_to_render ||= paragraphs.includes([:amendable, :category, :component, :scope]).limit(Decidim::EnhancedTextwork.config.participatory_space_highlighted_paragraphs_limit)
      end

      def paragraphs_count
        @paragraphs_count ||= paragraphs.count
      end
    end
  end
end
