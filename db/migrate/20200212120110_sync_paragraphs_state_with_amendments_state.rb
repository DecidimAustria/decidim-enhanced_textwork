# frozen_string_literal: true

class SyncParagraphsStateWithAmendmentsState < ActiveRecord::Migration[5.2]
  def up
    execute <<-SQL.squish
      UPDATE decidim_enhanced_textwork_paragraphs AS paragraphs
      SET state = amendments.state
      FROM decidim_amendments AS amendments
      WHERE
        paragraphs.state IS NULL AND
        amendments.decidim_emendation_type = 'Decidim::EnhancedTextwork::Paragraph' AND
        amendments.decidim_emendation_id = paragraphs.id AND
        amendments.state IS NOT NULL
    SQL
  end

  def down
    execute <<-SQL.squish
      UPDATE decidim_enhanced_textwork_paragraphs AS paragraphs
      SET state = NULL
      FROM decidim_amendments AS amendments
      WHERE
        amendments.decidim_emendation_type = 'Decidim::EnhancedTextwork::Paragraph' AND
        amendments.decidim_emendation_id = paragraphs.id AND
        amendments.state IS NOT NULL
    SQL
  end
end
