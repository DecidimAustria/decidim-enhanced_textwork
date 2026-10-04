# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class Revision < ApplicationRecord
      self.table_name = "decidim_textwork_revisions"
      belongs_to :section, class_name: "Decidim::EnhancedTextwork::Section", inverse_of: :revisions
      belongs_to :author, foreign_key: :decidim_author_id, class_name: "Decidim::User"
      has_many :supports, as: :supportable, class_name: "Decidim::EnhancedTextwork::Support"
      validates :title, :body, presence: true
      validates :number, uniqueness: { scope: :section_id }
      delegate :component, :organization, to: :section
      def readonly? = persisted?
    end
  end
end
