# frozen_string_literal: true

class AddReportCountToParagraphs < ActiveRecord::Migration[5.0]
  def change
    add_column :decidim_enhanced_textwork_paragraphs, :report_count, :integer, default: 0
  end
end
