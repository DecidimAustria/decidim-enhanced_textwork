# frozen_string_literal: true

class AddStatePublishedAtToParagraphs < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_enhanced_textwork_paragraphs, :state_published_at, :datetime
  end
end
