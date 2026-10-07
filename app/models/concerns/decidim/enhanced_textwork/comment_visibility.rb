# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    # Core comments otherwise remain readable/indexed after their Textwork
    # document is trashed. Other components retain Core's existing behaviour.
    module CommentVisibility
      def visible?
        return super unless textwork_root?

        super && root_commentable.visible? && !hidden? && !deleted?
      end

      def commentable?
        return super unless textwork_root?

        super && root_commentable.visible?
      end

      private

      def textwork_root?
        root_commentable.is_a?(Block) || root_commentable.is_a?(Suggestion)
      end
    end
  end
end
