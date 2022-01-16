# frozen_string_literal: true

require "cell/partial"

module Decidim
  module EnhancedTextwork
    # This cell renders the highlighted paragraphs for a given participatory
    # space. It is intended to be used in the `participatory_space_highlighted_elements`
    # view hook.
    class HighlightedParagraphsCell < Decidim::ViewModel
      include ParagraphCellsHelper

      private

      def published_components
        Decidim::Component
          .where(
            participatory_space: model,
            manifest_name: :paragraphs
          )
          .published
      end
    end
  end
end
