# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module CoreCommands
      module Like
        def call
          return super unless Participation.resource?(@resource)

          @resource.document.with_lock do
            @resource.reload
            return broadcast(:invalid) unless Participation.like_allowed?(@current_user, @resource, add: true)

            result = super
            if @resource.is_a?(Suggestion) && @resource.liked_by?(@current_user) && @resource.feedback_received_at.nil?
              @resource.update_column(:feedback_received_at, Time.current) # rubocop:disable Rails/SkipsModelValidations
            end
            result
          end
        end
      end

      module Unlike
        def call
          return super unless Participation.resource?(@resource)

          @resource.document.with_lock do
            @resource.reload
            return broadcast(:invalid) unless Participation.like_allowed?(@current_user, @resource, add: false)

            # Legacy Core likes may predate the feedback hook. Withdrawing them
            # must not make an already discussed suggestion editable again.
            if @resource.is_a?(Suggestion) && @resource.feedback_received_at.nil? && @resource.liked_by?(@current_user)
              first_feedback = @resource.likes.order(:created_at).pick(:created_at)
              @resource.update_column(:feedback_received_at, first_feedback) # rubocop:disable Rails/SkipsModelValidations
            end
            super
          end
        end
      end

      module Follow
        def call
          resource = @form.followable
          return super unless Participation.resource?(resource)

          resource.document.with_lock do
            resource.reload
            return broadcast(:invalid) unless Participation.follow_allowed?(@form.current_user, resource)

            super
          end
        end
      end

      module CreateComment
        def call
          resource = Participation.root(@form.commentable)
          return super unless Participation.resource?(resource)

          resource.document.with_lock do
            resource.reload
            return broadcast(:invalid) unless resource.user_allowed_to_comment?(@form.current_user)

            super
          end
        end
      end

      module UpdateComment
        def call
          resource = Participation.root(@comment)
          return super unless Participation.resource?(resource)

          resource.document.with_lock do
            resource.reload
            return broadcast(:invalid) unless resource.user_allowed_to_comment?(@form.current_user)

            super
          end
        end
      end

      module VoteComment
        def call
          resource = Participation.root(@comment)
          return super unless Participation.resource?(resource)

          resource.document.with_lock do
            resource.reload
            return broadcast(:invalid) unless resource.user_allowed_to_vote_comment?(@author)

            super
          end
        end
      end
    end
  end
end
