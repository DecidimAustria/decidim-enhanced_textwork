# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    # A paragraph can include a vote per user.
    class ParagraphVote < ApplicationRecord
      belongs_to :paragraph, foreign_key: "decidim_paragraph_id", class_name: "Decidim::EnhancedTextwork::Paragraph"
      belongs_to :author, foreign_key: "decidim_author_id", class_name: "Decidim::User"

      validates :paragraph, uniqueness: { scope: :author }
      validate :author_and_paragraph_same_organization
      validate :paragraph_not_rejected

      after_save :update_paragraph_votes_count
      after_destroy :update_paragraph_votes_count

      # Temporary votes are used when a minimum amount of votes is configured in
      # a component. They aren't taken into account unless the amount of votes
      # exceeds a threshold - meanwhile, they're marked as temporary.
      def self.temporary
        where(temporary: true)
      end

      # Final votes are votes that will be taken into account, that is, they're
      # not temporary.
      def self.final
        where(temporary: false)
      end

      private

      def update_paragraph_votes_count
        paragraph.update_votes_count
      end

      # Private: check if the paragraph and the author have the same organization
      def author_and_paragraph_same_organization
        return if !paragraph || !author

        errors.add(:paragraph, :invalid) unless author.organization == paragraph.organization
      end

      def paragraph_not_rejected
        return unless paragraph

        errors.add(:paragraph, :invalid) if paragraph.rejected?
      end
    end
  end
end
