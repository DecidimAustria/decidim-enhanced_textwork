# frozen_string_literal: true

class AddFollowableCounterCacheToParagraphs < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_enhanced_textwork_paragraphs, :follows_count, :integer, null: false, default: 0, index: true

    reversible do |dir|
      dir.up do
        Decidim::EnhancedTextwork::Paragraph.reset_column_information
        Decidim::EnhancedTextwork::Paragraph.find_each do |record|
          record.class.reset_counters(record.id, :follows)
        end
      end
    end
  end
end
