# frozen_string_literal: true

class AddCommentableCounterCacheToParagraphs < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_enhanced_textwork_paragraphs, :comments_count, :integer, null: false, default: 0, index: true
    add_column :decidim_enhanced_textwork_collaborative_drafts, :comments_count, :integer, null: false, default: 0, index: true
    Decidim::EnhancedTextwork::Paragraph.reset_column_information
    Decidim::EnhancedTextwork::Paragraph.find_each(&:update_comments_count)
    Decidim::EnhancedTextwork::CollaborativeDraft.reset_column_information
    Decidim::EnhancedTextwork::CollaborativeDraft.find_each(&:update_comments_count)
  end
end
