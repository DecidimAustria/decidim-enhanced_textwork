# frozen_string_literal: true

class UseMd5Indexes < ActiveRecord::Migration[5.2]
  def up
    remove_index :decidim_enhanced_textwork_paragraphs, name: "decidim_enhanced_textwork_paragraph_title_search"
    remove_index :decidim_enhanced_textwork_paragraphs, name: "decidim_enhanced_textwork_paragraph_body_search"
    execute "CREATE INDEX decidim_enhanced_textwork_paragraph_title_search ON decidim_enhanced_textwork_paragraphs(md5(title::text))"
    execute "CREATE INDEX decidim_enhanced_textwork_paragraph_body_search ON decidim_enhanced_textwork_paragraphs(md5(body::text))"
  end

  def down
    remove_index :decidim_enhanced_textwork_paragraphs, name: "decidim_enhanced_textwork_paragraph_title_search"
    remove_index :decidim_enhanced_textwork_paragraphs, name: "decidim_enhanced_textwork_paragraph_body_search"
    add_index :decidim_enhanced_textwork_paragraphs, :title, name: "decidim_enhanced_textwork_paragraph_title_search"
    add_index :decidim_enhanced_textwork_paragraphs, :body, name: "decidim_enhanced_textwork_paragraph_body_search"
  end
end
