# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class ContentForm < Decidim::Form
      attribute :title, String
      attribute :body, String
      attribute :reason, String
      attribute :base_revision_id, Integer
      validates :body, presence: true, length: { maximum: 1_000_000 }
      validates :reason, length: { maximum: 10_000 }, allow_nil: true
    end
  end
end
