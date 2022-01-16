# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      #  A command with all the business logic when an admin batch updates paragraphs category.
      class UpdateParagraphCategory < Rectify::Command
        # Public: Initializes the command.
        #
        # category_id - the category id to update
        # paragraph_ids - the paragraphs ids to update.
        def initialize(category_id, paragraph_ids)
          @category = Decidim::Category.find_by id: category_id
          @paragraph_ids = paragraph_ids
          @response = { category_name: "", successful: [], errored: [] }
        end

        # Executes the command. Broadcasts these events:
        #
        # - :update_paragraphs_category - when everything is ok, returns @response.
        # - :invalid_category - if the category is blank.
        # - :invalid_paragraph_ids - if the paragraph_ids is blank.
        #
        # Returns @response hash:
        #
        # - :category_name - the translated_name of the category assigned
        # - :successful - Array of names of the updated paragraphs
        # - :errored - Array of names of the paragraphs not updated because they already had the category assigned
        def call
          return broadcast(:invalid_category) if @category.blank?
          return broadcast(:invalid_paragraph_ids) if @paragraph_ids.blank?

          @response[:category_name] = @category.translated_name
          Paragraph.where(id: @paragraph_ids).find_each do |paragraph|
            if @category == paragraph.category
              @response[:errored] << paragraph.title
            else
              transaction do
                update_paragraph_category paragraph
                notify_author paragraph if paragraph.coauthorships.any?
              end
              @response[:successful] << paragraph.title
            end
          end

          broadcast(:update_paragraphs_category, @response)
        end

        private

        def update_paragraph_category(paragraph)
          paragraph.update!(
            category: @category
          )
        end

        def notify_author(paragraph)
          Decidim::EventsManager.publish(
            event: "decidim.events.enhanced_textwork.paragraph_update_category",
            event_class: Decidim::EnhancedTextwork::Admin::UpdateParagraphCategoryEvent,
            resource: paragraph,
            affected_users: paragraph.notifiable_identities
          )
        end
      end
    end
  end
end
