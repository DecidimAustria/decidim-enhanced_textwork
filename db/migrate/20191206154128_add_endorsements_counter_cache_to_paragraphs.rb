# frozen_string_literal: true

class AddEndorsementsCounterCacheToParagraphs < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_enhanced_textwork_paragraphs, :endorsements_count, :integer, null: false, default: 0
  end
end
