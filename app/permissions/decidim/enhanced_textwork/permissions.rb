# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class Permissions < Decidim::DefaultPermissions
      def permissions
        return permission_action unless user

        # Delegate the admin permission checks to the admin permissions class
        return Decidim::EnhancedTextwork::Admin::Permissions.new(user, permission_action, context).permissions if permission_action.scope == :admin
        return permission_action if permission_action.scope != :public

        case permission_action.subject
        when :paragraph
          apply_paragraph_permissions(permission_action)
        when :collaborative_draft
          apply_collaborative_draft_permissions(permission_action)
        else
          permission_action
        end

        permission_action
      end

      private

      def apply_paragraph_permissions(permission_action)
        case permission_action.action
        when :create
          can_create_paragraph?
        when :edit
          can_edit_paragraph?
        when :withdraw
          can_withdraw_paragraph?
        when :amend
          can_create_amendment?
        when :vote
          can_vote_paragraph?
        when :unvote
          can_unvote_paragraph?
        when :report
          true
        end
      end

      def paragraph
        @paragraph ||= context.fetch(:paragraph, nil) || context.fetch(:resource, nil)
      end

      def voting_enabled?
        return unless current_settings

        current_settings.votes_enabled? && !current_settings.votes_blocked?
      end

      def vote_limit_enabled?
        return unless component_settings

        component_settings.vote_limit.present? && component_settings.vote_limit.positive?
      end

      def remaining_votes
        return 1 unless vote_limit_enabled?

        paragraphs = Paragraph.where(component: component)
        votes_count = ParagraphVote.where(author: user, paragraph: paragraphs).size
        component_settings.vote_limit - votes_count
      end

      def can_create_paragraph?
        toggle_allow(authorized?(:create) && current_settings&.creation_enabled?)
      end

      def can_edit_paragraph?
        toggle_allow(paragraph && paragraph.editable_by?(user))
      end

      def can_withdraw_paragraph?
        toggle_allow(paragraph && paragraph.authored_by?(user))
      end

      def can_create_amendment?
        is_allowed = paragraph &&
                     authorized?(:amend, resource: paragraph) &&
                     current_settings&.amendments_enabled?

        toggle_allow(is_allowed)
      end

      def can_vote_paragraph?
        is_allowed = paragraph &&
                     authorized?(:vote, resource: paragraph) &&
                     voting_enabled? &&
                     remaining_votes.positive?

        toggle_allow(is_allowed)
      end

      def can_unvote_paragraph?
        is_allowed = paragraph &&
                     authorized?(:vote, resource: paragraph) &&
                     voting_enabled?

        toggle_allow(is_allowed)
      end

      def apply_collaborative_draft_permissions(permission_action)
        case permission_action.action
        when :create
          can_create_collaborative_draft?
        when :edit
          can_edit_collaborative_draft?
        when :publish
          can_publish_collaborative_draft?
        when :request_access
          can_request_access_collaborative_draft?
        when :react_to_request_access
          can_react_to_request_access_collaborative_draft?
        end
      end

      def collaborative_draft
        @collaborative_draft ||= context.fetch(:collaborative_draft, nil)
      end

      def collaborative_drafts_enabled?
        component_settings.collaborative_drafts_enabled
      end

      def can_create_collaborative_draft?
        return toggle_allow(false) unless collaborative_drafts_enabled?

        toggle_allow(current_settings&.creation_enabled? && authorized?(:create))
      end

      def can_edit_collaborative_draft?
        return toggle_allow(false) unless collaborative_drafts_enabled? && collaborative_draft.open?

        toggle_allow(collaborative_draft.editable_by?(user))
      end

      def can_publish_collaborative_draft?
        return toggle_allow(false) unless collaborative_drafts_enabled? && collaborative_draft.open?

        toggle_allow(collaborative_draft.created_by?(user))
      end

      def can_request_access_collaborative_draft?
        return toggle_allow(false) unless collaborative_drafts_enabled? && collaborative_draft.open?
        return toggle_allow(false) if collaborative_draft.requesters.include?(user)

        toggle_allow(!collaborative_draft.editable_by?(user))
      end

      def can_react_to_request_access_collaborative_draft?
        return toggle_allow(false) unless collaborative_drafts_enabled? && collaborative_draft.open?
        return toggle_allow(false) if collaborative_draft.requesters.include? user

        toggle_allow(collaborative_draft.created_by?(user))
      end
    end
  end
end
