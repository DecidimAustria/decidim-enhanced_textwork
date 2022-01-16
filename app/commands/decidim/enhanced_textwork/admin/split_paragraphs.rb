# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      # A command with all the business logic when an admin splits paragraphs from
      # one component to another.
      class SplitParagraphs < Rectify::Command
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

          broadcast(:ok, split_paragraphs)
        end

        private

        attr_reader :form

        def split_paragraphs
          transaction do
            form.paragraphs.flat_map do |original_paragraph|
              # If copying to the same component we only need one copy
              # but linking to the original paragraph links, not the
              # original paragraph.
              create_paragraph(original_paragraph)
              create_paragraph(original_paragraph) unless form.same_component?
            end
          end
        end

        def create_paragraph(original_paragraph)
          split_paragraph = Decidim::EnhancedTextwork::ParagraphBuilder.copy(
            original_paragraph,
            author: form.current_organization,
            action_user: form.current_user,
            extra_attributes: {
              component: form.target_component
            },
            skip_link: true
          )

          paragraphs_to_link = links_for(original_paragraph)
          split_paragraph.link_resources(paragraphs_to_link, "copied_from_component")
        end

        def links_for(paragraph)
          return paragraph unless form.same_component?

          paragraph.linked_resources(:paragraphs, "copied_from_component")
        end
      end
    end
  end
end
