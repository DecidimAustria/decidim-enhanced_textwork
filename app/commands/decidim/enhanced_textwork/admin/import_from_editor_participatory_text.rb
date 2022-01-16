# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      # A command with all the business logic when an admin imports paragraphs from
      # a participatory text rich text editor.
      class ImportFromEditorParticipatoryText < Rectify::Command
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
          return broadcast(:invalid) unless @form.valid?

          transaction do
            save_participatory_text_meta(@form)
            parse_participatory_text_content(@form)
          end

          broadcast(:ok)
          # rescue StandardError
          #   broadcast(:invalid_file)
        end

        private

        # Persist ParticipatoryText related meta information.
        def save_participatory_text_meta(form)
          document = ParticipatoryText.find_or_initialize_by(component: form.current_component)
          document.update!(title: form.title, description: form.description)
        end

        def parse_participatory_text_content(form)
          return if form.content.blank?

          markdown = Decidim::EnhancedTextwork::HtmlToMarkdown.new(form.content).to_md
          parser = MarkdownToParagraphs.new(form.current_component, form.current_user)
          parser.parse(markdown)
        end
      end
    end
  end
end
