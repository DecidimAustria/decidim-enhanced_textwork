# frozen_string_literal: true

class AddParticipatoryTextLevelToParagraphs < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_enhanced_textwork_paragraphs, :participatory_text_level, :string
  end
end
