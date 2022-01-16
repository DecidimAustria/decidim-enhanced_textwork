# frozen_string_literal: true

require "cell/partial"

module Decidim
  module EnhancedTextwork
    # This cell renders the linked resource of a paragraph.
    class ParagraphLinkedResourcesCell < Decidim::ViewModel
      def show
        render if linked_resource
      end
    end
  end
end
