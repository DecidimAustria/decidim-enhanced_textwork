# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class DocumentVersion < ApplicationRecord
      self.table_name = "decidim_textwork_document_versions"
      belongs_to :document, class_name: "Decidim::EnhancedTextwork::Document"
      belongs_to :author, foreign_key: :decidim_author_id, class_name: "Decidim::User"
      def readonly? = persisted?
    end
  end
end
