# frozen_string_literal: true

class MoveEnhancedTextworkAuthorshipsToCoauthorships < ActiveRecord::Migration[5.1]
  class Paragraph < ApplicationRecord
    self.table_name = :decidim_enhanced_textwork_paragraphs
  end
  class Coauthorship < ApplicationRecord
    self.table_name = :decidim_coauthorships
  end

  def change
    paragraphs = Paragraph.all

    paragraphs.each do |paragraph|
      author_id = paragraph.attributes["decidim_author_id"]
      user_group_id = paragraph.attributes["decidim_user_group_id"]

      next if author_id.nil?

      Coauthorship.create!(
        coauthorable_id: paragraph.id,
        coauthorable_type: "Decidim::EnhancedTextwork::Paragraph",
        decidim_author_id: author_id,
        decidim_user_group_id: user_group_id
      )
    end
  end
end
