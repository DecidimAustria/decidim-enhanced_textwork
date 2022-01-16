# frozen_string_literal: true

class FixUserGroupsIdsInParagraphsEndorsements < ActiveRecord::Migration[5.2]
  class ParagraphEndorsement < ApplicationRecord
    self.table_name = :decidim_enhanced_textwork_paragraph_endorsements
  end

  # rubocop:disable Rails/SkipsModelValidations
  def change
    Decidim::UserGroup.find_each do |group|
      old_id = group.extended_data["old_user_group_id"]
      next unless old_id

      Decidim::EnhancedTextwork::ParagraphEndorsement
        .where(decidim_user_group_id: old_id)
        .update_all(decidim_user_group_id: group.id)
    end
  end
  # rubocop:enable Rails/SkipsModelValidations
end
