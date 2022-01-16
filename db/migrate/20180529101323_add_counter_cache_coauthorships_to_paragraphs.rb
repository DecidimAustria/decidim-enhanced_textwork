# frozen_string_literal: true

class AddCounterCacheCoauthorshipsToParagraphs < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_enhanced_textwork_paragraphs, :coauthorships_count, :integer, null: false, default: 0
    add_index :decidim_enhanced_textwork_paragraphs, :coauthorships_count, name: "idx_decidim_enhanced_textwork_paragraphs_paragraph_coauth_cnt"
  end
end
