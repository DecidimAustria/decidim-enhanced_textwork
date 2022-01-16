# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    # A command with all the business logic when a user destroys a draft paragraph.
    class DestroyParagraph < Rectify::Command
      # Public: Initializes the command.
      #
      # paragraph     - The paragraph to destroy.
      # current_user - The current user.
      def initialize(paragraph, current_user)
        @paragraph = paragraph
        @current_user = current_user
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid and the paragraph is deleted.
      # - :invalid if the paragraph is not a draft.
      # - :invalid if the paragraph's author is not the current user.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) unless @paragraph.draft?
        return broadcast(:invalid) unless @paragraph.authored_by?(@current_user)

        @paragraph.destroy!

        broadcast(:ok, @paragraph)
      end
    end
  end
end
