# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      # A command with all the business logic to unassign paragraphs from a given
      # valuator.
      class UnassignParagraphsFromValuator < Rectify::Command
        # Public: Initializes the command.
        #
        # form - A form object with the params.
        def initialize(form)
          @form = form
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) unless form.valid?

          unassign_paragraphs
          broadcast(:ok)
        end

        private

        attr_reader :form

        def unassign_paragraphs
          transaction do
            form.paragraphs.flat_map do |paragraph|
              assignment = find_assignment(paragraph)
              unassign(assignment) if assignment
            end
          end
        end

        def find_assignment(paragraph)
          Decidim::EnhancedTextwork::ValuationAssignment.find_by(
            paragraph: paragraph,
            valuator_role: form.valuator_role
          )
        end

        def unassign(assignment)
          Decidim.traceability.perform_action!(
            :delete,
            assignment,
            form.current_user,
            paragraph_title: assignment.paragraph.title
          ) do
            assignment.destroy!
          end
        end
      end
    end
  end
end
