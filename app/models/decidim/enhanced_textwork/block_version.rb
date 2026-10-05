# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class BlockVersion < ApplicationRecord
      self.table_name = "decidim_textwork_block_versions"
      belongs_to :block, class_name: "Decidim::EnhancedTextwork::Block", inverse_of: :block_versions
      belongs_to :suggestion, class_name: "Decidim::EnhancedTextwork::Suggestion", optional: true
      belongs_to :author, foreign_key: :decidim_author_id, class_name: "Decidim::User", optional: true
      validates :number, uniqueness: { scope: :block_id }, numericality: { only_integer: true, greater_than: 0 }
      validates :body, presence: true
      validates :origin, inclusion: { in: %w(import suggestion editorial) }
      def readonly? = persisted?
    end
  end
end
