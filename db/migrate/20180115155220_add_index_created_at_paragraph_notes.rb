# frozen_string_literal: true

class AddIndexCreatedAtParagraphNotes < ActiveRecord::Migration[5.1]
  def change
    add_index :decidim_enhanced_textwork_paragraph_notes, :created_at
  end
end
