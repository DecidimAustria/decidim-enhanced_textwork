# frozen_string_literal: true

class AddPositionToParagraphs < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_enhanced_textwork_paragraphs, :position, :integer
  end
end
