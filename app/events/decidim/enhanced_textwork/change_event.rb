# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class ChangeEvent < Decidim::Events::SimpleEvent
      i18n_attributes :decision_reason
      def decision_reason
        return "" unless resource.is_a?(Suggestion)

        ERB::Util.html_escape(resource.reading(:answer, I18n.locale))
      end

      def resource_text = decision_reason
    end
  end
end
