# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      # A common abstract to be used by the Merge and Split paragraphs forms.
      class ParagraphsForkForm < Decidim::Form
        mimic :paragraphs_import

        attribute :target_component_id, Integer
        attribute :paragraph_ids, Array

        validates :target_component, :paragraphs, :current_component, presence: true
        validate :same_participatory_space
        validate :mergeable_to_same_component

        def paragraphs
          @paragraphs ||= Decidim::EnhancedTextwork::Paragraph.where(component: current_component, id: paragraph_ids).uniq
        end

        def target_component
          return current_component if clean_target_component_id == current_component.id

          @target_component ||= current_component.siblings.find_by(id: target_component_id)
        end

        def same_component?
          target_component == current_component
        end

        private

        def errors_set
          @errors_set ||= Set[]
        end

        def mergeable_to_same_component
          return true unless same_component?

          paragraphs.each do |paragraph|
            errors_set << :not_official unless paragraph.official?
            errors_set << :supported if paragraph.votes.any? || paragraph.endorsements.any?
          end

          errors_set.each { |error| errors.add(:base, error) } if errors_set.any?
        end

        def same_participatory_space
          return if !target_component || !current_component

          errors.add(:target_component, :invalid) if current_component.participatory_space != target_component.participatory_space
        end

        # Private: Returns the id of the target component.
        #
        # We receive this as ["id"] since it's from a select in a form.
        def clean_target_component_id
          target_component_id.first.to_i
        end
      end
    end
  end
end
