# frozen_string_literal: true

class CreateParagraphEndorsements < ActiveRecord::Migration[5.1]
  def change
    create_table :decidim_enhanced_textwork_paragraph_endorsements do |t|
      t.references :decidim_paragraph, null: false, index: { name: "decidim_enhanced_textwork_paragraph_endorsement_paragraph" }
      t.references :decidim_author, null: false, index: { name: "decidim_enhanced_textwork_paragraph_endorsement_author" }
      t.references :decidim_user_group, null: true, index: { name: "decidim_enhanced_textwork_paragraph_endorsement_user_group" }

      t.timestamps
    end

    add_index :decidim_enhanced_textwork_paragraph_endorsements, "decidim_paragraph_id, decidim_author_id, (coalesce(decidim_user_group_id,-1))", unique: true, name:
      "decidim_enhanced_textwork_paragraph_endorsmt_p_auth_ugrp_uniq"
  end
end
