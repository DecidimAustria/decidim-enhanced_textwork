# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      # A command with all the business logic when an admin creates a private note paragraph.
      class CreateParagraphNote < Rectify::Command
        # Public: Initializes the command.
        #
        # form         - A form object with the params.
        # paragraph - the paragraph to relate.
        def initialize(form, paragraph)
          @form = form
          @paragraph = paragraph
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid, together with the note paragraph.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if form.invalid?

          create_paragraph_note
          notify_admins_and_valuators

          broadcast(:ok, paragraph_note)
        end

        private

        attr_reader :form, :paragraph_note, :paragraph

        def create_paragraph_note
          @paragraph_note = Decidim.traceability.create!(
            ParagraphNote,
            form.current_user,
            {
              body: form.body,
              paragraph: paragraph,
              author: form.current_user
            },
            resource: {
              title: paragraph.title
            }
          )
        end

        def notify_admins_and_valuators
          affected_users = Decidim::User.org_admins_except_me(form.current_user).all
          affected_users += Decidim::EnhancedTextwork::ValuationAssignment.includes(valuator_role: :user).where.not(id: form.current_user.id).where(paragraph: paragraph).map(&:valuator)

          data = {
            event: "decidim.events.enhanced_textwork.admin.paragraph_note_created",
            event_class: Decidim::EnhancedTextwork::Admin::ParagraphNoteCreatedEvent,
            resource: paragraph,
            affected_users: affected_users
          }

          Decidim::EventsManager.publish(data)
        end
      end
    end
  end
end
