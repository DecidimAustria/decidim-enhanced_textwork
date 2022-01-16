# frozen_string_literal: true

class FixCountersForCopiedParagraphs < ActiveRecord::Migration[5.2]
  def up
    copies_ids = Decidim::ResourceLink
                 .where(
                   name: "copied_from_component",
                   from_type: "Decidim::EnhancedTextwork::Paragraph",
                   to_type: "Decidim::EnhancedTextwork::Paragraph"
                 ).pluck(:to_id)

    Decidim::EnhancedTextwork::Paragraph.where(id: copies_ids).find_each do |record|
      record.class.reset_counters(record.id, :follows)
      record.update_comments_count
    end
  end

  def down; end
end
