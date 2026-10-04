# frozen_string_literal: true

class CreateStandaloneTextwork < ActiveRecord::Migration[7.2]
  def change
    create_table :decidim_textwork_documents do |t|
      t.references :decidim_component, null: false, index: { unique: true }, foreign_key: true
      t.jsonb :title, null: false, default: {}
      t.jsonb :description, null: false, default: {}
      t.datetime :published_at
      t.timestamps
    end
    create_table :decidim_textwork_sections do |t|
      t.references :document, null: false, foreign_key: { to_table: :decidim_textwork_documents }
      t.references :decidim_component, null: false, foreign_key: true
      t.integer :position, null: false
      t.string :level, null: false, default: "article"
      t.integer :comments_count, null: false, default: 0
      t.integer :follows_count, null: false, default: 0
      t.timestamps
    end
    create_table :decidim_textwork_revisions do |t|
      t.references :section, null: false, foreign_key: { to_table: :decidim_textwork_sections }
      t.references :decidim_author, null: false, foreign_key: { to_table: :decidim_users }
      t.integer :number, null: false
      t.jsonb :title, null: false, default: {}
      t.jsonb :body, null: false, default: {}
      t.datetime :created_at, null: false
    end
    add_index :decidim_textwork_revisions, [:section_id, :number], unique: true
    add_reference :decidim_textwork_sections, :current_revision, foreign_key: { to_table: :decidim_textwork_revisions }
    create_table :decidim_textwork_amendments do |t|
      t.references :section, null: false, foreign_key: { to_table: :decidim_textwork_sections }
      t.references :decidim_component, null: false, foreign_key: true
      t.references :base_revision, null: false, foreign_key: { to_table: :decidim_textwork_revisions }
      t.references :result_revision, foreign_key: { to_table: :decidim_textwork_revisions }
      t.references :decidim_author, null: false, foreign_key: { to_table: :decidim_users }
      t.references :decided_by, foreign_key: { to_table: :decidim_users }
      t.jsonb :title, null: false, default: {}
      t.jsonb :body, null: false, default: {}
      t.text :reason
      t.text :decision_reason
      t.string :state, null: false, default: "pending"
      t.datetime :decided_at
      t.integer :comments_count, null: false, default: 0
      t.integer :follows_count, null: false, default: 0
      t.timestamps
    end
    create_table :decidim_textwork_supports do |t|
      t.references :supportable, polymorphic: true, null: false
      t.references :decidim_author, null: false, foreign_key: { to_table: :decidim_users }
      t.timestamps
    end
    add_index :decidim_textwork_supports, [:supportable_type, :supportable_id, :decidim_author_id], unique: true, name: "textwork_unique_support"
    create_table :decidim_textwork_document_versions do |t|
      t.references :document, null: false, foreign_key: { to_table: :decidim_textwork_documents }
      t.references :decidim_author, null: false, foreign_key: { to_table: :decidim_users }
      t.integer :number, null: false
      t.jsonb :snapshot, null: false
      t.datetime :created_at, null: false
    end
    add_index :decidim_textwork_document_versions, [:document_id, :number], unique: true
  end
end
