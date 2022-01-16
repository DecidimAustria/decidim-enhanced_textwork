# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    # Custom helpers, scoped to the paragraphs engine.
    module ControlVersionHelper
      def item_name
        versioned_resource.model_name.singular_route_key.to_sym
      end
    end
  end
end
