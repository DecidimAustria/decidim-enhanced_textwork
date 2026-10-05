# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      class ImportForm < Decidim::Form
        include TranslatableAttributes

        translatable_attribute :title, String
        translatable_attribute :description, String
        attribute :locale, String, default: -> { I18n.locale.to_s }
        validates :locale, inclusion: { in: ->(form) { form.current_organization.available_locales } }
        attribute :content, String
        attribute :document, Object
        validates :title, translatable_presence: true
        validates :content, presence: true, unless: :document_present?
        validates :content, length: { maximum: 1_000_000 }
        validate :component_must_be_empty
        def document_present?
          document.present?
        end

        def component_must_be_empty
          errors.add(:content, I18n.t("decidim.textwork.existing_document")) if Document.with_deleted.exists?(component: current_component)
        end
      end
    end
  end
end
