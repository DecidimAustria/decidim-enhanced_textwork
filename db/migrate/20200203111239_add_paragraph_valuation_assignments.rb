# frozen_string_literal: true

class AddParagraphValuationAssignments < ActiveRecord::Migration[5.2]
  def change
    create_table :decidim_enhanced_textwork_valuation_assignments do |t|
      t.references :decidim_paragraph, null: false, index: { name: "decidim_enhanced_textwork_valuation_assignment_paragraph" }
      t.references :valuator_role, polymorphic: true, null: false, index: { name: "decidim_enhanced_textwork_valuation_assignment_valuator_role" }

      t.timestamps
    end
  end
end
