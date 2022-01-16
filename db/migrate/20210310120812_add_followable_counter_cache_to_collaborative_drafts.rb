# frozen_string_literal: true

class AddFollowableCounterCacheToCollaborativeDrafts < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_enhanced_textwork_collaborative_drafts, :follows_count, :integer, null: false, default: 0, index: true

    reversible do |dir|
      dir.up do
        Decidim::EnhancedTextwork::CollaborativeDraft.reset_column_information
        Decidim::EnhancedTextwork::CollaborativeDraft.find_each do |record|
          record.class.reset_counters(record.id, :follows)
        end
      end
    end
  end
end
