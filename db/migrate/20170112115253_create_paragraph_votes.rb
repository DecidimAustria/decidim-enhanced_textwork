# frozen_string_literal: true

class CreateParagraphVotes < ActiveRecord::Migration[5.0]
  def change
    create_table :decidim_enhanced_textwork_paragraph_votes do |t|
      t.references :decidim_paragraph, null: false, index: { name: "decidim_enhanced_textwork_paragraph_vote_paragraph" }
      t.references :decidim_author, null: false, index: { name: "decidim_enhanced_textwork_paragraph_vote_author" }

      t.timestamps
    end

    add_index :decidim_enhanced_textwork_paragraph_votes, [:decidim_paragraph_id, :decidim_author_id], unique: true, name: "decidim_enhanced_textwork_paragraph_vote_author_unique"
  end
end
