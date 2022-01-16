# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      # A command with all the business logic when an admin merges paragraphs from
      # one component to another.
      class MergeParagraphs < Rectify::Command
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

          broadcast(:ok, merge_paragraphs)
        end

        private

        attr_reader :form

        def merge_paragraphs
          transaction do
            merged_paragraph = create_new_paragraph
            merged_paragraph.link_resources(paragraphs_to_link, "copied_from_component")
            form.paragraphs.each(&:destroy!) if form.same_component?
            merged_paragraph
          end
        end

        def paragraphs_to_link
          return previous_links if form.same_component?

          form.paragraphs
        end

        def previous_links
          @previous_links ||= form.paragraphs.flat_map do |paragraph|
            paragraph.linked_resources(:paragraphs, "copied_from_component")
          end
        end

        def create_new_paragraph
          original_paragraph = form.paragraphs.first

          Decidim::EnhancedTextwork::ParagraphBuilder.copy(
            original_paragraph,
            author: form.current_organization,
            action_user: form.current_user,
            extra_attributes: {
              component: form.target_component
            },
            skip_link: true
          )
        end
      end
    end
  end
end
