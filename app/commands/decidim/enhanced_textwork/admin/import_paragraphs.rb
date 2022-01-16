# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      # A command with all the business logic when an admin imports paragraphs from
      # one component to another.
      class ImportParagraphs < Rectify::Command
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

          broadcast(:ok, import_paragraphs)
        end

        private

        attr_reader :form

        def import_paragraphs
          paragraphs.map do |original_paragraph|
            next if paragraph_already_copied?(original_paragraph, target_component)

            Decidim::EnhancedTextwork::ParagraphBuilder.copy(
              original_paragraph,
              author: paragraph_author,
              action_user: form.current_user,
              extra_attributes: {
                "component" => target_component
              }.merge(paragraph_answer_attributes(original_paragraph))
            )
          end.compact
        end

        def paragraphs
          @paragraphs = Decidim::EnhancedTextwork::Paragraph
                       .where(component: origin_component)
                       .where(state: paragraph_states)
          @paragraphs = @paragraphs.where(scope: paragraph_scopes) unless paragraph_scopes.empty?
          @paragraphs
        end

        def paragraph_states
          @paragraph_states = @form.states

          if @form.states.include?("not_answered")
            @paragraph_states.delete("not_answered")
            @paragraph_states.push(nil)
          end

          @paragraph_states
        end

        def paragraph_scopes
          @form.scopes
        end

        def origin_component
          @form.origin_component
        end

        def target_component
          @form.current_component
        end

        def paragraph_already_copied?(original_paragraph, target_component)
          original_paragraph.linked_resources(:paragraphs, "copied_from_component").any? do |paragraph|
            paragraph.component == target_component
          end
        end

        def paragraph_author
          form.keep_authors ? nil : @form.current_organization
        end

        def paragraph_answer_attributes(original_paragraph)
          return {} unless form.keep_answers

          {
            answer: original_paragraph.answer,
            answered_at: original_paragraph.answered_at,
            state: original_paragraph.state,
            state_published_at: original_paragraph.state_published_at
          }
        end
      end
    end
  end
end
