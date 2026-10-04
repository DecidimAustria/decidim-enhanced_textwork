# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class TextsController < ApplicationController
      def show
        @document = Document.where(component: current_component).where.not(published_at: nil).first
        @paragraphs = @document ? @document.sections.not_hidden.includes(:current_revision) : Section.none
        @active_paragraph = @paragraphs.find(params[:paragraph_id]) if params[:paragraph_id].present?
      end
    end
  end
end
