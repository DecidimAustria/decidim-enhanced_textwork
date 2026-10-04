# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class SectionsController < ApplicationController
      def show
        @section = visible_sections.find(params[:id])
        @revision = params[:revision_id].present? ? @section.revisions.find(params[:revision_id]) : @section.current_revision
      end
    end
  end
end
