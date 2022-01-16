# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    # This controller is the abstract class from which all other controllers of
    # this engine inherit.
    #
    # Note that it inherits from `Decidim::Components::BaseController`, which
    # override its layout and provide all kinds of useful methods.
    class ApplicationController < Decidim::Components::BaseController
      helper Decidim::Messaging::ConversationHelper
      helper_method :paragraph_limit_reached?

      def paragraph_limit
        return nil if component_settings.paragraph_limit.zero?

        component_settings.paragraph_limit
      end

      def paragraph_limit_reached?
        return false unless paragraph_limit

        paragraphs.where(author: current_user).count >= paragraph_limit
      end

      def paragraphs
        Paragraph.where(component: current_component)
      end
    end
  end
end
