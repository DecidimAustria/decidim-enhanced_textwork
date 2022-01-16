# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    #
    # Decorator for collaborative drafts
    #
    class CollaborativeDraftPresenter < ParagraphPresenter
      def author
        coauthorship = __getobj__.coauthorships.first
        @author ||= if coauthorship.user_group
                      Decidim::UserGroupPresenter.new(coauthorship.user_group)
                    else
                      Decidim::UserPresenter.new(coauthorship.author)
                    end
      end

      alias collaborative_draft paragraph

      def collaborative_draft_path
        Decidim::ResourceLocatorPresenter.new(collaborative_draft).path
      end
    end
  end
end
