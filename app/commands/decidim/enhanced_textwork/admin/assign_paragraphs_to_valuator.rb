# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      # A command with all the business logic to assign paragraphs to a given
      # valuator.
      class AssignParagraphsToValuator < Rectify::Command
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

          assign_paragraphs
          broadcast(:ok)
        rescue ActiveRecord::RecordInvalid
          broadcast(:invalid)
        end

        private

        attr_reader :form

        def assign_paragraphs
          transaction do
            form.paragraphs.flat_map do |paragraph|
              find_assignment(paragraph) || assign_paragraph(paragraph)
            end
          end
        end

        def find_assignment(paragraph)
          Decidim::EnhancedTextwork::ValuationAssignment.find_by(
            paragraph: paragraph,
            valuator_role: form.valuator_role
          )
        end

        def assign_paragraph(paragraph)
          Decidim.traceability.create!(
            Decidim::EnhancedTextwork::ValuationAssignment,
            form.current_user,
            paragraph: paragraph,
            valuator_role: form.valuator_role
          )
        end
      end
    end
  end
end
