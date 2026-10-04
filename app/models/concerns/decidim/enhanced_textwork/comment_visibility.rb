# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module CommentVisibility
      def accepts_new_comments? = visible? && super
      def user_allowed_to_comment?(user) = visible? && accepts_new_comments? && super
      def user_allowed_to_vote_comment?(user) = visible? && super
    end
  end
end
