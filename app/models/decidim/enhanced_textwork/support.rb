# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class Support < ApplicationRecord
      self.table_name = "decidim_textwork_supports"
      belongs_to :supportable, polymorphic: true
      belongs_to :author, foreign_key: :decidim_author_id, class_name: "Decidim::User"
      validates :decidim_author_id, uniqueness: { scope: [:supportable_type, :supportable_id] }
      validate :valid_target
      def valid_target
        unless supportable.is_a?(Revision) || supportable.is_a?(Amendment)
          errors.add(:supportable, :invalid)
          return
        end
        errors.add(:author, :invalid) unless author&.organization == supportable.organization
      end
    end
  end
end
