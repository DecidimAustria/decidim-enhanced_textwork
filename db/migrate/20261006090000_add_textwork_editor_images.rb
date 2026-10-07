# frozen_string_literal: true

class AddTextworkEditorImages < ActiveRecord::Migration[7.2]
  def change
    add_reference :decidim_textwork_blocks, :editor_image, foreign_key: { to_table: :decidim_editor_images }
    add_column :decidim_textwork_blocks, :image_alt, :text, null: false, default: ""
  end
end
