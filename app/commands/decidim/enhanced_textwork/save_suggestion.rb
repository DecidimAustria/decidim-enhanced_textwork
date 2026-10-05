# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class SaveSuggestion < Decidim::Command
      # Named optional inputs preserve the command API for creation and editing.
      # rubocop:disable Metrics/ParameterLists
      def initialize(block, user, body:, expected_version:, justification: "", suggestion: nil)
        @block = block
        @user = user
        @body = body
        @justification = justification
        @expected_version = expected_version
        @suggestion = suggestion
      end

      # rubocop:enable Metrics/ParameterLists

      def call
        return broadcast(:forbidden) unless allowed?

        @block.document.with_lock do
          @block.reload
          return broadcast(:forbidden) unless allowed?
          return broadcast(:conflict) unless @block.current_version_number == @expected_version.to_i

          return broadcast(:forbidden) unless editable?

          record = @suggestion || @block.suggestions.build(component: @block.component, author: @user)
          record.block_version = @block.current_version
          record.changeset = { original: @block.original, replace: @body }
          record.replace_original(:body, @body)
          record.replace_original(:justification, @justification)
          return broadcast(:invalid, record) unless record.save

          Notifications.deliver("suggestion_created", record, @block.notification_scope.followers.to_a, @user) unless @suggestion
          broadcast(:ok, record)
        end
      end

      private

      def editable?
        return true unless @suggestion

        @suggestion.lock!
        @suggestion.block == @block && @suggestion.editable_by?(@user)
      end

      def allowed?
        Access.allowed?(@user, @block, :suggest) && @block.paragraph? && !@block.component.current_settings.suggestions_blocked
      end
    end
  end
end
