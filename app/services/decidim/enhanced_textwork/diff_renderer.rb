# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class DiffRenderer < Decidim::BaseDiffRenderer
      private

      def attribute_types = { title: :i18n, body: :i18n, description: :i18n, justification: :i18n, answer: :i18n, status: :string }

      def i18n_scope = "decidim.textwork"
    end
  end
end
