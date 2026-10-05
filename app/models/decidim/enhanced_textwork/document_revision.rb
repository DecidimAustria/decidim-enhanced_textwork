# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class DocumentRevision < ApplicationRecord
      self.table_name = "decidim_textwork_document_revisions"
      belongs_to :document, class_name: "Decidim::EnhancedTextwork::Document"
      belongs_to :block, class_name: "Decidim::EnhancedTextwork::Block", optional: true
      belongs_to :author, foreign_key: :decidim_author_id, class_name: "Decidim::User"
      validates :number, uniqueness: { scope: :document_id }
      validates :kind, inclusion: { in: %w(import block_added block_removed block_moved) }
      def readonly? = persisted?
    end
  end
end
