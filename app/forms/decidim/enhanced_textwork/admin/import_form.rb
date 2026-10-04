# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      class ImportForm < Decidim::Form
        include TranslatableAttributes

        translatable_attribute :title, String
        translatable_attribute :description, String
        attribute :content, String

        validates :title, translatable_presence: true
        validates :content, presence: true, length: { maximum: 1_000_000 }
        validate :component_must_be_empty

        def component_must_be_empty
          return unless Decidim::Proposals::Proposal.where(component: current_component).exists?

          errors.add(:content, I18n.t("decidim.enhanced_textwork.admin.existing_paragraphs"))
        end
      end
    end
  end
end
