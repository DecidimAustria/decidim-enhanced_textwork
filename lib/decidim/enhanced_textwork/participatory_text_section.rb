# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    # The data store for a Paragraph in the Decidim::EnhancedTextwork component.
    module ParticipatoryTextSection
      extend ActiveSupport::Concern

      LEVELS = {
        section: "section", sub_section: "sub-section", article: "article"
      }.freeze

      included do
        # Public: is this section an :article?
        def article?
          participatory_text_level == LEVELS[:article]
        end
      end
    end
  end
end
