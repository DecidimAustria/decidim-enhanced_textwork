# frozen-string_literal: true

module Decidim
  module EnhancedTextwork
    class ParagraphMentionedEvent < Decidim::Events::SimpleEvent
      include Decidim::ApplicationHelper

      i18n_attributes :mentioned_paragraph_title

      private

      def mentioned_paragraph_title
        present(mentioned_paragraph).title
      end

      def mentioned_paragraph
        @mentioned_paragraph ||= Decidim::EnhancedTextwork::Paragraph.find(extra[:mentioned_paragraph_id])
      end
    end
  end
end
