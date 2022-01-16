# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class WidgetsController < Decidim::WidgetsController
      helper EnhancedTextwork::ApplicationHelper

      private

      def model
        @model ||= Paragraph.where(component: params[:component_id]).find(params[:paragraph_id])
      end

      def iframe_url
        @iframe_url ||= paragraph_widget_url(model)
      end
    end
  end
end
