# frozen_string_literal: true

class AddPublishedAtToParagraphs < ActiveRecord::Migration[5.1]
  def up
    add_column :decidim_enhanced_textwork_paragraphs, :published_at, :datetime, index: true
    # rubocop:disable Rails/SkipsModelValidations
    Decidim::EnhancedTextwork::Paragraph.update_all("published_at = updated_at")
    # rubocop:enable Rails/SkipsModelValidations
  end

  def down
    remove_column :decidim_enhanced_textwork_paragraphs, :published_at
  end
end
