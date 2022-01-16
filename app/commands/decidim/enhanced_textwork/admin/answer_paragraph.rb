# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      # A command with all the business logic when an admin answers a paragraph.
      class AnswerParagraph < Rectify::Command
        # Public: Initializes the command.
        #
        # form - A form object with the params.
        # paragraph - The paragraph to write the answer for.
        def initialize(form, paragraph)
          @form = form
          @paragraph = paragraph
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if form.invalid?

          store_initial_paragraph_state

          transaction do
            answer_paragraph
            notify_paragraph_answer
          end

          broadcast(:ok)
        end

        private

        attr_reader :form, :paragraph, :initial_has_state_published, :initial_state

        def answer_paragraph
          Decidim.traceability.perform_action!(
            "answer",
            paragraph,
            form.current_user
          ) do
            attributes = {
              state: form.state,
              answer: form.answer,
              answered_at: Time.current,
              cost: form.cost,
              cost_report: form.cost_report,
              execution_period: form.execution_period
            }

            attributes[:state_published_at] = Time.current if !initial_has_state_published && form.publish_answer?

            paragraph.update!(attributes)
          end
        end

        def notify_paragraph_answer
          return if !initial_has_state_published && !form.publish_answer?

          NotifyParagraphAnswer.call(paragraph, initial_state)
        end

        def store_initial_paragraph_state
          @initial_has_state_published = paragraph.published_state?
          @initial_state = paragraph.state
        end
      end
    end
  end
end
