# frozen_string_literal: true

class AddHiddenAtToParagraphs < ActiveRecord::Migration[5.0]
  def change
    add_column :decidim_enhanced_textwork_paragraphs, :hidden_at, :datetime
  end
end
