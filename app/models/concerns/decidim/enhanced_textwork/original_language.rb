# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module OriginalLanguage
      extend ActiveSupport::Concern

      def original(field = :body) = self[field].to_h[original_locale].to_s

      def original_locale = respond_to?(:locale) ? locale : document.locale

      # Retain manual translations separately; stale text must not look current.
      def replace_original(field, text)
        old = self[field].to_h
        return if old[original_locale] == text

        stale = outdated_translations.deep_dup
        manual = old.except(original_locale, "machine_translations")
        stale[field.to_s] = stale.fetch(field.to_s, {}).merge(manual) if manual.any?
        self.outdated_translations = stale
        self[field] = { original_locale => text }
      end

      def reading(field, locale, machine: true)
        data = self[field].to_h
        data[locale.to_s].presence || (machine && data.dig("machine_translations", locale.to_s).presence) || original(field)
      end
    end
  end
end
