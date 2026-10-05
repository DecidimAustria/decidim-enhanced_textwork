# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class TranslationJob < Decidim::ApplicationJob
      queue_as :translations
      retry_on StandardError, wait: :polynomially_long, attempts: 3
      def perform(request)
        return unless %w(queued failed).include?(request.status)

        klass = Decidim.machine_translation_service_klass
        return request.update!(status: "failed") unless klass

        klass.new(request, :payload, request.payload.fetch(request.source_locale), request.target_locale, request.source_locale).translate
      rescue StandardError
        request.update!(status: "failed") if request&.persisted?
        raise
      end
    end
  end
end
