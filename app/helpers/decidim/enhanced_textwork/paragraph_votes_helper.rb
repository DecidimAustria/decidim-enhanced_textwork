# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    # Simple helpers to handle markup variations for paragraph votes partials
    module ParagraphVotesHelper
      # Returns the css classes used for paragraph votes count in both paragraphs list and show pages
      #
      # from_paragraphs_list - A boolean to indicate if the template is rendered from the paragraphs list page
      #
      # Returns a hash with the css classes for the count number and label
      def votes_count_classes(from_paragraphs_list)
        return { number: "card__support__number", label: "" } if from_paragraphs_list

        { number: "extra__suport-number", label: "extra__suport-text" }
      end

      # Returns the css classes used for paragraph vote button in both paragraphs list and show pages
      #
      # from_paragraphs_list - A boolean to indicate if the template is rendered from the paragraphs list page
      #
      # Returns a string with the value of the css classes.
      def vote_button_classes(from_paragraphs_list)
        return "card__button" if from_paragraphs_list

        "expanded"
      end

      # Public: Gets the vote limit for each user, if set.
      #
      # Returns an Integer if set, nil otherwise.
      def vote_limit
        return nil if component_settings.vote_limit.zero?

        component_settings.vote_limit
      end

      # Check if the vote limit is enabled for the current component
      #
      # Returns true if the vote limit is enabled
      def vote_limit_enabled?
        vote_limit.present?
      end

      # Public: Checks if threshold per paragraph are set.
      #
      # Returns true if set, false otherwise.
      def threshold_per_paragraph_enabled?
        threshold_per_paragraph.present?
      end

      # Public: Fetches the maximum amount of votes per paragraph.
      #
      # Returns an Integer with the maximum amount of votes, nil otherwise.
      def threshold_per_paragraph
        return nil unless component_settings.threshold_per_paragraph.positive?

        component_settings.threshold_per_paragraph
      end

      # Public: Checks if can accumulate more than maxium is enabled
      #
      # Returns true if enabled, false otherwise.
      def can_accumulate_supports_beyond_threshold?
        component_settings.can_accumulate_supports_beyond_threshold
      end

      # Public: Checks if voting is enabled in this step.
      #
      # Returns true if enabled, false otherwise.
      def votes_enabled?
        current_settings.votes_enabled
      end

      # Public: Checks if voting is blocked in this step.
      #
      # Returns true if blocked, false otherwise.
      def votes_blocked?
        current_settings.votes_blocked
      end

      # Public: Checks if the current user is allowed to vote in this step.
      #
      # Returns true if the current user can vote, false otherwise.
      def current_user_can_vote?
        current_user && votes_enabled? && vote_limit_enabled? && !votes_blocked?
      end

      # Return the remaining votes for a user if the current component has a vote limit
      #
      # user - A User object
      #
      # Returns a number with the remaining votes for that user
      def remaining_votes_count_for(user)
        return 0 unless vote_limit_enabled?

        paragraphs = Paragraph.where(component: current_component)
        votes_count = ParagraphVote.where(author: user, paragraph: paragraphs).size
        component_settings.vote_limit - votes_count
      end
    end
  end
end
