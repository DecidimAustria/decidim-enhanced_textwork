# frozen_string_literal: true

class RemoveIndexCounterCacheCoauthorshipsToParagraphs < ActiveRecord::Migration[5.2]
  def change
    remove_index :decidim_enhanced_textwork_paragraphs, name: "idx_decidim_enhanced_textwork_paragraphs_paragraph_coauth_cnt"
  end
end
