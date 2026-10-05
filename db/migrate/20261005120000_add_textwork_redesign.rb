# frozen_string_literal: true

# Additive: alpha2 sections, revisions and supports are preserved, not reinterpreted.
class AddTextworkRedesign < ActiveRecord::Migration[7.2]
  def change
    change_table :decidim_textwork_documents do |t|
      t.string :locale, null: false, default: "en"
      t.datetime :deleted_at
      t.integer :likes_count, null: false, default: 0
      t.integer :follows_count, null: false, default: 0
      t.jsonb :outdated_translations, null: false, default: {}
    end
    create_table :decidim_textwork_blocks do |t|
      t.references :document, null: false, foreign_key: { to_table: :decidim_textwork_documents }
      t.references :decidim_component, null: false, foreign_key: true
      t.string :kind, null: false
      t.integer :depth, null: false, default: 1
      t.integer :position, null: false
      t.jsonb :body, null: false, default: {}
      t.jsonb :outdated_translations, null: false, default: {}
      t.integer :current_version_number, null: false, default: 1
      t.integer :comments_count, null: false, default: 0
      t.integer :likes_count, null: false, default: 0
      t.integer :follows_count, null: false, default: 0
      t.datetime :removed_at
      t.timestamps
    end
    add_index :decidim_textwork_blocks, [:document_id, :position], where: "removed_at IS NULL"
    create_table :decidim_textwork_block_versions do |t|
      t.references :block, null: false, foreign_key: { to_table: :decidim_textwork_blocks }
      t.integer :number, null: false
      t.text :body, null: false
      t.string :origin, null: false
      t.boolean :adjusted, null: false, default: false
      t.references :decidim_author, foreign_key: { to_table: :decidim_users }
      t.datetime :created_at, null: false
    end
    add_index :decidim_textwork_block_versions, [:block_id, :number], unique: true
    create_table :decidim_textwork_suggestions do |t|
      t.references :block, null: false, foreign_key: { to_table: :decidim_textwork_blocks }
      t.references :decidim_component, null: false, foreign_key: true
      t.references :block_version, null: false, foreign_key: { to_table: :decidim_textwork_block_versions }
      t.references :decidim_author, polymorphic: true, null: false
      t.references :decided_by, foreign_key: { to_table: :decidim_users }
      t.jsonb :changeset, null: false, default: {}
      t.jsonb :body, null: false, default: {}
      t.jsonb :justification, null: false, default: {}
      t.jsonb :answer, null: false, default: {}
      t.jsonb :outdated_translations, null: false, default: {}
      t.string :status, null: false, default: "pending"
      t.datetime :answered_at
      t.datetime :feedback_received_at
      t.integer :comments_count, null: false, default: 0
      t.integer :likes_count, null: false, default: 0
      t.timestamps
    end
    add_reference :decidim_textwork_block_versions, :suggestion, foreign_key: { to_table: :decidim_textwork_suggestions }
    create_table :decidim_textwork_document_revisions do |t|
      t.references :document, null: false, foreign_key: { to_table: :decidim_textwork_documents }
      t.references :block, foreign_key: { to_table: :decidim_textwork_blocks }
      t.references :decidim_author, null: false, foreign_key: { to_table: :decidim_users }
      t.integer :number, null: false
      t.string :kind, null: false
      t.jsonb :details, null: false, default: {}
      t.text :note
      t.datetime :created_at, null: false
    end
    add_index :decidim_textwork_document_revisions, [:document_id, :number], unique: true
    create_table :decidim_textwork_translation_requests do |t|
      t.references :resource, polymorphic: true, null: false
      t.string :field_name, null: false
      t.string :source_locale, null: false
      t.string :target_locale, null: false
      t.string :source_digest, null: false
      t.jsonb :payload, null: false, default: {}
      t.string :status, null: false, default: "pending"
      t.timestamps
    end
    add_index :decidim_textwork_translation_requests,
              [:resource_type, :resource_id, :field_name, :target_locale, :source_digest],
              unique: true, name: "textwork_unique_translation"
  end
end
