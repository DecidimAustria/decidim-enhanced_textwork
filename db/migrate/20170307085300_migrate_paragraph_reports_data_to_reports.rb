# frozen_string_literal: true

class MigrateParagraphReportsDataToReports < ActiveRecord::Migration[5.0]
  class Decidim::EnhancedTextwork::ParagraphReport < ApplicationRecord
    belongs_to :user, foreign_key: "decidim_user_id", class_name: "Decidim::User"
    belongs_to :paragraph, foreign_key: "decidim_paragraph_id", class_name: "Decidim::EnhancedTextwork::Paragraph"
  end

  def change
    Decidim::EnhancedTextwork::ParagraphReport.find_each do |paragraph_report|
      moderation = Decidim::Moderation.find_or_create_by!(reportable: paragraph_report.paragraph,
                                                          participatory_process: paragraph_report.paragraph.feature.participatory_space)
      Decidim::Report.create!(moderation: moderation,
                              user: paragraph_report.user,
                              reason: paragraph_report.reason,
                              details: paragraph_report.details)
      moderation.update!(report_count: moderation.report_count + 1)
    end

    drop_table :decidim_enhanced_textwork_paragraph_reports
    remove_column :decidim_enhanced_textwork_paragraphs, :report_count
    remove_column :decidim_enhanced_textwork_paragraphs, :hidden_at
  end
end
