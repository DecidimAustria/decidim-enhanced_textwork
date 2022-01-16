# frozen_string_literal: true

require "cell/partial"

module Decidim
  module EnhancedTextwork
    class AmendmentCell < Decidim::ViewModel
      include Cell::ViewModel::Partial
      include Decidim::SanitizeHelper
      include ParagraphCellsHelper

      def show
        render
      end

      private

      def emendation
        model.emendation
      end

      def emendation_author
        present(model.emendation.authors.first)
      end

      def emendation_excerpt
        truncate(decidim_sanitize(translated_attribute(model.emendation.body), strip_tags: true), length: 200)
      end

      def created_at
        I18n.l model.created_at, format: :long
      end

      def compare_emendation_path
        compare_paragraph_path(model.emendation)
      end
    end
  end
end
