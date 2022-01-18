# frozen_string_literal: true

class CreateEnhancedTextworkParticipatoryTexts < ActiveRecord::Migration[5.2]
  def change
    create_table :decidim_enhanced_textwork_participatory_texts do |t|
      t.jsonb :title
      t.jsonb :description
      t.belongs_to :decidim_component, null: false, index: { name: "idx_enhanced_textwork_participatory_texts_decidim_component_id" }

      t.timestamps
    end
  end
end
