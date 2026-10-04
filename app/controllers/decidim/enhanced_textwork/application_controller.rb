# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class ApplicationController < Decidim::Components::BaseController
      include Decidim::FormFactory
      helper Decidim::EnhancedTextwork::TextsHelper
      helper Decidim::FollowableHelper
      helper Decidim::Comments::CommentsHelper
      rescue_from Decidim::ActionForbidden, with: -> { head :forbidden }
      private

      def published_document
        @document ||= Document.where(component: current_component).where.not(published_at: nil).first!
      end

      def visible_sections
        published_document.sections.not_hidden.includes(:current_revision)
      end

      def visible_amendments
        Amendment.where(section: visible_sections, component: current_component).not_hidden
      end

      def ensure_allowed!(resource, action)
        raise Decidim::ActionForbidden unless Access.allowed?(current_user, resource, action)
      end
    end
  end
end
