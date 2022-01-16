# frozen_string_literal: true

class CreateParagraphReports < ActiveRecord::Migration[5.0]
  def change
    create_table :decidim_enhanced_textwork_paragraph_reports do |t|
      t.references :decidim_paragraph, null: false, index: { name: "decidim_enhanced_textwork_paragraph_result_paragraph" }
      t.references :decidim_user, null: false, index: { name: "decidim_enhanced_textwork_paragraph_result_user" }
      t.string :reason, null: false
      t.text :details

      t.timestamps
    end

    add_index :decidim_enhanced_textwork_paragraph_reports, [:decidim_paragraph_id, :decidim_user_id], unique: true, name: "decidim_enhanced_textwork_paragraph_report_paragraph_user_uniq"
  end
end
