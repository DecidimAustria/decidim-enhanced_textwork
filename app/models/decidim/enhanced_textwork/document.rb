# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class Document < ApplicationRecord
      self.table_name = "decidim_textwork_documents"
      include Decidim::HasComponent
      component_manifest_name "textwork"
      has_many :sections, -> { order(:position, :id) }, class_name: "Decidim::EnhancedTextwork::Section", inverse_of: :document
      has_many :document_versions, class_name: "Decidim::EnhancedTextwork::DocumentVersion", inverse_of: :document
      validates :title, presence: true
      def published? = published_at.present?

      def snapshot!(author)
        document_versions.create!(author:, number: (document_versions.maximum(:number) || 0) + 1,
                                  snapshot: { title:, description:, sections: sections.map { |s|
                                    { id: s.id, position: s.position, level: s.level, revision_id: s.current_revision_id }
                                  } })
      end
    end
  end
end
