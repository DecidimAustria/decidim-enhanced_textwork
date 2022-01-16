# frozen_string_literal: true

class AddCounterCacheVotesToParagraphs < ActiveRecord::Migration[5.0]
  def change
    add_column :decidim_enhanced_textwork_paragraphs, :paragraph_votes_count, :integer, null: false, default: 0
  end
end
