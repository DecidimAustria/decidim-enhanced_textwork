# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class ApplicationController < Decidim::Components::BaseController
      include Decidim::FormFactory

      helper Decidim::EnhancedTextwork::ReadingHelper
      helper Decidim::FollowableHelper
      helper Decidim::Comments::CommentsHelper
      rescue_from Decidim::ActionForbidden, with: -> { head :forbidden }
      private

      def published_document
        @document ||= begin
          scope = Document.published.where(component: current_component)
          params[:document_id].presence || (controller_name == "documents" && params[:id].presence) ? scope.find(params[:document_id] || params[:id]) : scope.first!
        end
      end

      def ensure_allowed!(resource, action)
        raise Decidim::ActionForbidden unless Access.allowed?(current_user, resource, action)
      end
    end
  end
end
