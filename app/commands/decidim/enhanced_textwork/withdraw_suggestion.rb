# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class WithdrawSuggestion < Decidim::Command
      def initialize(suggestion, user)
        @suggestion = suggestion
        @user = user
      end

      def call
        @suggestion.document.with_lock do
          @suggestion.reload
          return broadcast(:forbidden) unless @suggestion.withdrawable_by?(@user)

          @suggestion.update!(status: "withdrawn")
          broadcast(:ok, @suggestion)
        end
      end
    end
  end
end
