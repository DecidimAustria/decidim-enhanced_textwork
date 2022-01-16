# frozen_string_literal: true

class AddTemporaryVotes < ActiveRecord::Migration[5.2]
  def change
    change_table :decidim_enhanced_textwork_paragraph_votes do |t|
      t.boolean :temporary, null: false, default: false
    end
  end
end
