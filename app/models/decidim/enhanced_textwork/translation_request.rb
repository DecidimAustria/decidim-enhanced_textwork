# frozen_string_literal: true

require "digest"
module Decidim
  module EnhancedTextwork
    # A version-bound adapter for Decidim's configured translation provider.
    # Providers save to this proxy through the unchanged Core save job. Only a
    # still-current source is copied to the real resource, without text versions.
    class TranslationRequest < ApplicationRecord
      self.table_name = "decidim_textwork_translation_requests"
      belongs_to :resource, polymorphic: true
      delegate :organization, to: :resource
      def self.translatable_fields_list = [:payload]

      def self.request(resource, field, target)
        return unless translation_needed?(resource, field, target)

        key = { resource:, field_name: field.to_s, target_locale: target.to_s,
                source_digest: Digest::SHA256.hexdigest(resource.original(field)) }
        record = create_or_find_by!(key) do |request|
          request.source_locale = resource.original_locale
          request.payload = { resource.original_locale => resource.original(field) }
        end
        record.with_lock do
          if %w(pending obsolete).include?(record.status) || (record.status == "failed" && record.updated_at < 5.minutes.ago)
            record.update!(status: "queued")
            TranslationJob.perform_later(record)
          end
        end
        if record.status == "completed"
          record.update_column(:payload, record.payload) # rubocop:disable Rails/SkipsModelValidations
          resource.reload
          return
        end
        record
      end

      def self.translation_needed?(resource, field, target)
        return false unless resource.class.translatable_fields_list.include?(field.to_sym)
        return false if target.to_s == resource.original_locale || resource.original(field).blank?
        return false unless resource.organization.available_locales.include?(target.to_s)
        return false unless resource.organization.enable_machine_translations? && Decidim.machine_translation_service_klass

        resource[field].to_h[target.to_s].blank? && resource[field].to_h.dig("machine_translations", target.to_s).blank?
      end

      # This override belongs only to the adapter, never to a Core model/job.
      # Saving derived text deliberately bypasses content callbacks and versions.
      # rubocop:disable Rails/SkipsModelValidations
      def update_column(name, value)
        return super unless name.to_s == "payload"

        translated = value.dig("machine_translations", target_locale)
        resource.with_lock do
          current = Digest::SHA256.hexdigest(resource.original(field_name))
          if current == source_digest && resource.original_locale == source_locale && translated.present?
            field = resource[field_name].deep_dup
            field["machine_translations"] = field.fetch("machine_translations", {}).merge(target_locale => translated)
            resource.update_column(field_name, field)
            update_columns(payload: value, status: "completed")
          else
            update_columns(status: "obsolete")
          end
        end
      end
      # rubocop:enable Rails/SkipsModelValidations
    end
  end
end
