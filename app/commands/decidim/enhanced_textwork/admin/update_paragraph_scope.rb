# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      #  A command with all the business logic when an admin batch updates paragraphs scope.
      class UpdateParagraphScope < Rectify::Command
        include TranslatableAttributes
        # Public: Initializes the command.
        #
        # scope_id - the scope id to update
        # paragraph_ids - the paragraphs ids to update.
        def initialize(scope_id, paragraph_ids)
          @scope = Decidim::Scope.find_by id: scope_id
          @paragraph_ids = paragraph_ids
          @response = { scope_name: "", successful: [], errored: [] }
        end

        # Executes the command. Broadcasts these events:
        #
        # - :update_paragraphs_scope - when everything is ok, returns @response.
        # - :invalid_scope - if the scope is blank.
        # - :invalid_paragraph_ids - if the paragraph_ids is blank.
        #
        # Returns @response hash:
        #
        # - :scope_name - the translated_name of the scope assigned
        # - :successful - Array of names of the updated paragraphs
        # - :errored - Array of names of the paragraphs not updated because they already had the scope assigned
        def call
          return broadcast(:invalid_scope) if @scope.blank?
          return broadcast(:invalid_paragraph_ids) if @paragraph_ids.blank?

          update_paragraphs_scope

          broadcast(:update_paragraphs_scope, @response)
        end

        private

        attr_reader :scope, :paragraph_ids

        def update_paragraphs_scope
          @response[:scope_name] = translated_attribute(scope.name, scope.organization)
          Paragraph.where(id: paragraph_ids).find_each do |paragraph|
            if scope == paragraph.scope
              @response[:errored] << paragraph.title
            else
              transaction do
                update_paragraph_scope paragraph
                notify_author paragraph if paragraph.coauthorships.any?
              end
              @response[:successful] << paragraph.title
            end
          end
        end

        def update_paragraph_scope(paragraph)
          paragraph.update!(
            scope: scope
          )
        end

        def notify_author(paragraph)
          Decidim::EventsManager.publish(
            event: "decidim.events.enhanced_textwork.paragraph_update_scope",
            event_class: Decidim::EnhancedTextwork::Admin::UpdateParagraphScopeEvent,
            resource: paragraph,
            affected_users: paragraph.notifiable_identities
          )
        end
      end
    end
  end
end
