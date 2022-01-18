# frozen_string_literal: true

class AddEnhancedTextworkCreatedInMeeting < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_enhanced_textwork_paragraphs, :created_in_meeting, :boolean, default: false
  end
end
