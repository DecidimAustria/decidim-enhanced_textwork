# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class NotifyParagraphsMentionedJob < ApplicationJob
      def perform(comment_id, linked_paragraphs)
        comment = Decidim::Comments::Comment.find(comment_id)

        linked_paragraphs.each do |paragraph_id|
          paragraph = Paragraph.find(paragraph_id)
          affected_users = paragraph.notifiable_identities

          Decidim::EventsManager.publish(
            event: "decidim.events.enhanced_textwork.paragraph_mentioned",
            event_class: Decidim::EnhancedTextwork::ParagraphMentionedEvent,
            resource: comment.root_commentable,
            affected_users: affected_users,
            extra: {
              comment_id: comment.id,
              mentioned_paragraph_id: paragraph_id
            }
          )
        end
      end
    end
  end
end
