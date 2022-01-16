# frozen-string_literal: true

module Decidim
  module EnhancedTextwork
    class EvaluatingParagraphEvent < Decidim::Events::SimpleEvent
      def event_has_roles?
        true
      end
    end
  end
end
