# frozen_string_literal: true

class CreateDecidimParagraphs < ActiveRecord::Migration[5.0]
  def change
    create_table :decidim_enhanced_textwork_paragraphs do |t|
      t.text :title, null: false
      t.text :body, null: false
      t.references :decidim_feature, index: true, null: false, index: { name: "index_decidim_enhanced_textwork_paragraphs_decidim_feature_id" }
      t.references :decidim_author, index: true
      t.references :decidim_category, index: true, index: { name: "index_decidim_enhanced_textwork_paragraphs_decidim_category_id" }
      t.references :decidim_scope, index: true

      t.timestamps
    end
  end
end
