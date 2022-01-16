# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      # A command with all the business logic when an admin imports paragraphs from
      # a participatory text.
      class PublishParticipatoryText < UpdateParticipatoryText
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
            publish_drafts
          end

          if @failures.any?
            broadcast(:invalid, @failures)
          else
            broadcast(:ok)
          end
        end

        private

        attr_reader :form

        def publish_drafts
          Decidim::EnhancedTextwork::Paragraph.where(component: form.current_component).drafts.find_each do |paragraph|
            add_failure(paragraph) unless publish_paragraph(paragraph)
          end
          raise ActiveRecord::Rollback if @failures.any?
        end

        def add_failure(paragraph)
          @failures[paragraph.id] = paragraph.errors.full_messages
        end

        # This will be the PaperTrail version shown in the version control feature (1 of 1).
        # For an attribute to appear in the new version it has to be reset
        # and reassigned, as PaperTrail only keeps track of object CHANGES.
        def publish_paragraph(paragraph)
          title, body = reset_paragraph_title_and_body(paragraph)

          Decidim.traceability.perform_action!(:create, paragraph, form.current_user, visibility: "all") do
            paragraph.update(title: title, body: body, published_at: Time.current)
          end
        end

        # Reset the attributes to an empty string and return the old values.
        def reset_paragraph_title_and_body(paragraph)
          title = paragraph.title
          body = paragraph.body

          PaperTrail.request(enabled: false) do
            # rubocop:disable Rails/SkipsModelValidations
            paragraph.update_columns(
              title: { I18n.locale => "" },
              body: { I18n.locale => "" }
            )
            # rubocop:enable Rails/SkipsModelValidations
          end

          [title, body]
        end
      end
    end
  end
end
