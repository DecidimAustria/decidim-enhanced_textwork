# frozen_string_literal: true

class RemoveNotNullReferenceParagraphs < ActiveRecord::Migration[5.0]
  def change
    change_column_null :decidim_enhanced_textwork_paragraphs, :reference, true
  end
end
