# frozen_string_literal: true

class MigrateParagraphsCategory < ActiveRecord::Migration[5.1]
  def change
    # Create categorizations ensuring database integrity
    execute('
      INSERT INTO decidim_categorizations(decidim_category_id, categorizable_id, categorizable_type, created_at, updated_at)
        SELECT decidim_category_id, decidim_enhanced_textwork_paragraphs.id, \'Decidim::EnhancedTextwork::Paragraph\', NOW(), NOW()
        FROM decidim_enhanced_textwork_paragraphs
        INNER JOIN decidim_categories ON decidim_categories.id = decidim_enhanced_textwork_paragraphs.decidim_category_id
    ')
    # Remove unused column
    remove_column :decidim_enhanced_textwork_paragraphs, :decidim_category_id
  end
end
