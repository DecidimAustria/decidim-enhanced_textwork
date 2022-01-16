# frozen_string_literal: true

class MakeAuthorPolymorhpicForParagraphEndorsements < ActiveRecord::Migration[5.2]
  class ParagraphEndorsement < ApplicationRecord
    self.table_name = :decidim_enhanced_textwork_paragraph_endorsements
  end

  def change
    remove_index :decidim_enhanced_textwork_paragraph_endorsements, :decidim_author_id

    add_column :decidim_enhanced_textwork_paragraph_endorsements, :decidim_author_type, :string

    reversible do |direction|
      direction.up do
        execute <<~SQL.squish
          UPDATE decidim_enhanced_textwork_paragraph_endorsements
          SET decidim_author_type = 'Decidim::UserBaseEntity'
        SQL
      end
    end

    add_index :decidim_enhanced_textwork_paragraph_endorsements,
              [:decidim_author_id, :decidim_author_type],
              name: "index_decidim_enhanced_textwork_p_endorsmnts_on_decidim_author"

    change_column_null :decidim_enhanced_textwork_paragraph_endorsements, :decidim_author_id, false
    change_column_null :decidim_enhanced_textwork_paragraph_endorsements, :decidim_author_type, false

    ParagraphEndorsement.reset_column_information
  end
end
