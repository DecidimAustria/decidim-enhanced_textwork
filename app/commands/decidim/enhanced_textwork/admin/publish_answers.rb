# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      # A command with all the business logic to publish many answers at once.
      class PublishAnswers < Rectify::Command
        # Public: Initializes the command.
        #
        # component - The component that contains the answers.
        # user - the Decidim::User that is publishing the answers.
        # paragraph_ids - the identifiers of the paragraphs with the answers to be published.
        def initialize(component, user, paragraph_ids)
          @component = component
          @user = user
          @paragraph_ids = paragraph_ids
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if there are not paragraphs to publish.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) unless paragraphs.any?

          paragraphs.each do |paragraph|
            transaction do
              mark_paragraph_as_answered(paragraph)
              notify_paragraph_answer(paragraph)
            end
          end

          broadcast(:ok)
        end

        private

        attr_reader :component, :user, :paragraph_ids

        def paragraphs
          @paragraphs ||= Decidim::EnhancedTextwork::Paragraph
                         .published
                         .answered
                         .state_not_published
                         .where(component: component)
                         .where(id: paragraph_ids)
        end

        def mark_paragraph_as_answered(paragraph)
          Decidim.traceability.perform_action!(
            "publish_answer",
            paragraph,
            user
          ) do
            paragraph.update!(state_published_at: Time.current)
          end
        end

        def notify_paragraph_answer(paragraph)
          NotifyParagraphAnswer.call(paragraph, nil)
        end
      end
    end
  end
end
