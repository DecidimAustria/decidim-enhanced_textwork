# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    # A paragraph can include a notes created by admins.
    class ParagraphNote < ApplicationRecord
      include Decidim::Traceable
      include Decidim::Loggable

      belongs_to :paragraph, foreign_key: "decidim_paragraph_id", class_name: "Decidim::EnhancedTextwork::Paragraph", counter_cache: true
      belongs_to :author, foreign_key: "decidim_author_id", class_name: "Decidim::User"

      default_scope { order(created_at: :asc) }

      def self.log_presenter_class_for(_log)
        Decidim::EnhancedTextwork::AdminLog::ParagraphNotePresenter
      end
    end
  end
end
