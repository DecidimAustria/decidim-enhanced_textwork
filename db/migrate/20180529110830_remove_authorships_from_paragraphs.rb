# frozen_string_literal: true

class RemoveAuthorshipsFromParagraphs < ActiveRecord::Migration[5.1]
  def change
    remove_column :decidim_enhanced_textwork_paragraphs, :decidim_author_id, :integer
    remove_column :decidim_enhanced_textwork_paragraphs, :decidim_user_group_id, :integer
  end
end
