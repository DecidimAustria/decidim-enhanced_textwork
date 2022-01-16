# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    # A command with all the business logic when a user votes a paragraph.
    class VoteParagraph < Rectify::Command
      # Public: Initializes the command.
      #
      # paragraph     - A Decidim::EnhancedTextwork::Paragraph object.
      # current_user - The current user.
      def initialize(paragraph, current_user)
        @paragraph = paragraph
        @current_user = current_user
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid, together with the paragraph vote.
      # - :invalid if the form wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) if @paragraph.maximum_votes_reached? && !@paragraph.can_accumulate_supports_beyond_threshold

        build_paragraph_vote
        return broadcast(:invalid) unless vote.valid?

        ActiveRecord::Base.transaction do
          @paragraph.with_lock do
            vote.save!
            update_temporary_votes
          end
        end

        Decidim::Gamification.increment_score(@current_user, :paragraph_votes)

        broadcast(:ok, vote)
      end

      attr_reader :vote

      private

      def component
        @component ||= @paragraph.component
      end

      def minimum_votes_per_user
        component.settings.minimum_votes_per_user
      end

      def minimum_votes_per_user?
        minimum_votes_per_user.positive?
      end

      def update_temporary_votes
        return unless minimum_votes_per_user? && user_votes.count >= minimum_votes_per_user

        user_votes.each { |vote| vote.update(temporary: false) }
      end

      def user_votes
        @user_votes ||= ParagraphVote.where(
          author: @current_user,
          paragraph: Paragraph.where(component: component)
        )
      end

      def build_paragraph_vote
        @vote = @paragraph.votes.build(
          author: @current_user,
          temporary: minimum_votes_per_user?
        )
      end
    end
  end
end
