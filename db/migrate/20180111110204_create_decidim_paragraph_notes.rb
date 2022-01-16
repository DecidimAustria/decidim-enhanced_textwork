# frozen_string_literal: true

class CreateDecidimParagraphNotes < ActiveRecord::Migration[5.1]
  def change
    create_table :decidim_enhanced_textwork_paragraph_notes do |t|
      t.references :decidim_paragraph, null: false, index: { name: "decidim_enhanced_textwork_paragraph_note_paragraph" }
      t.references :decidim_author, null: false, index: { name: "decidim_enhanced_textwork_paragraph_note_author" }
      t.text :body, null: false

      t.timestamps
    end

    add_column :decidim_enhanced_textwork_paragraphs, :paragraph_notes_count, :integer, null: false, default: 0
  end
end
