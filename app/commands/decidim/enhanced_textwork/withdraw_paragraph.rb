# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    # A command with all the business logic when a user withdraws a new paragraph.
    class WithdrawParagraph < Rectify::Command
      # Public: Initializes the command.
      #
      # paragraph     - The paragraph to withdraw.
      # current_user - The current user.
      def initialize(paragraph, current_user)
        @paragraph = paragraph
        @current_user = current_user
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid, together with the paragraph.
      # - :has_supports if the paragraph already has supports or does not belong to current user.
      #
      # Returns nothing.
      def call
        return broadcast(:has_supports) if @paragraph.votes.any?

        transaction do
          change_paragraph_state_to_withdrawn
          reject_emendations_if_any
        end

        broadcast(:ok, @paragraph)
      end

      private

      def change_paragraph_state_to_withdrawn
        @paragraph.update state: "withdrawn"
      end

      def reject_emendations_if_any
        return if @paragraph.emendations.empty?

        @paragraph.emendations.each do |emendation|
          @form = form(Decidim::Amendable::RejectForm).from_params(id: emendation.amendment.id)
          result = Decidim::Amendable::Reject.call(@form)
          return result[:ok] if result[:ok]
        end
      end
    end
  end
end
