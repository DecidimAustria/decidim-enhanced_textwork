# frozen_string_literal: true

# This migration must be executed after CreateDecidimEndorsements migration in decidim-core.
class MoveParagraphEndorsementsToCoreEndorsements < ActiveRecord::Migration[5.2]
  class ParagraphEndorsement < ApplicationRecord
    self.table_name = :decidim_enhanced_textwork_paragraph_endorsements
  end

  class Endorsement < ApplicationRecord
    self.table_name = :decidim_endorsements
  end

  # Move ParagraphEndorsements to Endorsements
  def up
    non_duplicated_group_endorsements = ParagraphEndorsement.select(
      "MIN(id) as id, decidim_user_group_id"
    ).group(:decidim_user_group_id).where.not(decidim_user_group_id: nil).map(&:id)

    ParagraphEndorsement.where("id IN (?) OR decidim_user_group_id IS NULL", non_duplicated_group_endorsements).find_each do |prop_endorsement|
      Endorsement.create!(
        resource_type: Decidim::EnhancedTextwork::Paragraph.name,
        resource_id: prop_endorsement.decidim_paragraph_id,
        decidim_author_type: prop_endorsement.decidim_author_type,
        decidim_author_id: prop_endorsement.decidim_author_id,
        decidim_user_group_id: prop_endorsement.decidim_user_group_id
      )
    end
    # update new `decidim_enhanced_textwork_paragraph.endorsements_count` counter cache
    Decidim::EnhancedTextwork::Paragraph.select(:id).all.find_each do |paragraph|
      Decidim::EnhancedTextwork::Paragraph.reset_counters(paragraph.id, :endorsements)
    end
  end

  def down
    non_duplicated_group_endorsements = Endorsement.select(
      "MIN(id) as id, decidim_user_group_id"
    ).group(:decidim_user_group_id).where.not(decidim_user_group_id: nil).map(&:id)

    Endorsement
      .where(resource_type: "Decidim::EnhancedTextwork::Paragraph")
      .where("id IN (?) OR decidim_user_group_id IS NULL", non_duplicated_group_endorsements).find_each do |endorsement|
      ParagraphEndorsement.find_or_create_by!(
        decidim_paragraph_id: endorsement.resource_id,
        decidim_author_type: endorsement.decidim_author_type,
        decidim_author_id: endorsement.decidim_author_id,
        decidim_user_group_id: endorsement.decidim_user_group_id
      )
    end
    # update `decidim_enhanced_textwork_paragraph.paragraph_endorsements_count` counter cache
    Decidim::EnhancedTextwork::Paragraph.select(:id).all.find_each do |paragraph|
      Decidim::EnhancedTextwork::Paragraph.reset_counters(paragraph.id, :paragraph_endorsements)
    end
  end
end
