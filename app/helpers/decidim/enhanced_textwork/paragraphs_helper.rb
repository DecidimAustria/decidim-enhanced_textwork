# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    # Simple helpers to handle markup variations for paragraphs
    module ParagraphsHelper
      def paragraph_reason_callout_announcement
        {
          title: paragraph_reason_callout_title,
          body: decidim_sanitize(translated_attribute(@paragraph.answer))
        }
      end

      def paragraph_reason_callout_class
        case @paragraph.state
        when "accepted"
          "success"
        when "evaluating"
          "warning"
        when "rejected"
          "alert"
        else
          ""
        end
      end

      def paragraph_reason_callout_title
        i18n_key = case @paragraph.state
                   when "evaluating"
                     "paragraph_in_evaluation_reason"
                   else
                     "paragraph_#{@paragraph.state}_reason"
                   end

        t(i18n_key, scope: "decidim.enhanced_textwork.paragraphs.show")
      end

      def filter_paragraphs_state_values
        Decidim::CheckBoxesTreeHelper::TreeNode.new(
          Decidim::CheckBoxesTreeHelper::TreePoint.new("", t("decidim.enhanced_textwork.application_helper.filter_state_values.all")),
          [
            Decidim::CheckBoxesTreeHelper::TreePoint.new("accepted", t("decidim.enhanced_textwork.application_helper.filter_state_values.accepted")),
            Decidim::CheckBoxesTreeHelper::TreePoint.new("evaluating", t("decidim.enhanced_textwork.application_helper.filter_state_values.evaluating")),
            Decidim::CheckBoxesTreeHelper::TreePoint.new("state_not_published", t("decidim.enhanced_textwork.application_helper.filter_state_values.not_answered")),
            Decidim::CheckBoxesTreeHelper::TreePoint.new("rejected", t("decidim.enhanced_textwork.application_helper.filter_state_values.rejected"))
          ]
        )
      end

      def paragraph_has_costs?
        @paragraph.cost.present? &&
          translated_attribute(@paragraph.cost_report).present? &&
          translated_attribute(@paragraph.execution_period).present?
      end

      def resource_version(resource, options = {})
        return unless resource.respond_to?(:amendable?) && resource.amendable?

        super
      end
    end
  end
end
