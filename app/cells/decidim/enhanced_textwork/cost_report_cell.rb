# frozen_string_literal: true

require "cell/partial"

module Decidim
  module EnhancedTextwork
    # This cell renders the cost report for a paragraph.
    class CostReportCell < Decidim::ViewModel
      include ActionView::Helpers::NumberHelper
      include Decidim::SanitizeHelper
      include Decidim::LayoutHelper
      include ParagraphCellsHelper

      private

      def cost
        number_to_currency(model.cost, unit: Decidim.currency_unit)
      end

      def cost_report
        decidim_sanitize(translated_attribute(model.cost_report).html_safe)
      end

      def needs_text_toggle?
        cost_report != cost_report_short
      end

      def cost_report_short
        decidim_sanitize(
          html_truncate(
            translated_attribute(model.cost_report).html_safe,
            length: 200
          )
        )
      end

      def execution_period
        decidim_sanitize(translated_attribute(model.execution_period).html_safe)
      end
    end
  end
end
