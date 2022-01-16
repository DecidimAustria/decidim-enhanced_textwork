# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      # A command with all the business logic when an admin updates participatory text paragraphs.
      class UpdateParticipatoryText < Rectify::Command
        include Decidim::TranslatableAttributes

        # Public: Initializes the command.
        #
        # form - A PreviewParticipatoryTextForm form object with the params.
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
          transaction do
            @failures = {}
            update_contents_and_resort_paragraphs(form)
          end

          if @failures.any?
            broadcast(:invalid, @failures)
          else
            broadcast(:ok)
          end
        end

        private

        attr_reader :form

        # Prevents PaperTrail from creating versions while updating participatory text paragraphs.
        # A first version will be created when publishing the Participatory Text.
        def update_contents_and_resort_paragraphs(form)
          PaperTrail.request(enabled: false) do
            form.paragraphs.each do |prop_form|
              add_failure(prop_form) if prop_form.invalid?

              paragraph = Paragraph.where(component: form.current_component).find(prop_form.id)
              paragraph.set_list_position(prop_form.position) if paragraph.position != prop_form.position
              paragraph.title = { I18n.locale => translated_attribute(prop_form.title) }
              paragraph.body = if paragraph.participatory_text_level == ParticipatoryTextSection::LEVELS[:article]
                                { I18n.locale => translated_attribute(prop_form.body) }
                              else
                                { I18n.locale => "" }
                              end

              add_failure(paragraph) unless paragraph.save
            end
          end
          raise ActiveRecord::Rollback if @failures.any?
        end

        def add_failure(paragraph)
          @failures[paragraph.id] = paragraph.errors.full_messages
        end
      end
    end
  end
end
