# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class DocumentsController < ApplicationController
      helper Decidim::EnhancedTextwork::ReadingHelper
      def index
        document = Document.published.find_by(component: current_component)
        return render(:empty) unless document

        redirect_to document_path(document)
      end

      def show
        @document = published_document
        @blocks = @document.blocks.active.ordered.includes(:block_versions).to_a
        @numbers = @document.numbering
        @pending_counts = Suggestion.not_hidden.where(block: @blocks, status: "pending").group(:block_id).count
      end

      def panel
        @document = published_document
        @block = @document.blocks.find(params[:block])
        return render partial: "unavailable", locals: { removed: true } if @block.removed?
        raise ActiveRecord::RecordNotFound unless @block.paragraph?

        load_suggestions
        return render(partial: "unavailable", locals: { removed: false }) if params[:suggestion].present? && !@suggestion

        select_mode!

        render partial: "panel"
      end

      def history
        @document = published_document
        @history = (@document.document_revisions.includes(:author,
                                                          :block).to_a + BlockVersion.where(block: @document.blocks).includes(:author, :block).to_a).sort_by(&:created_at).reverse
      end

      private

      def load_suggestions
        @suggestions = @block.suggestions.listed.includes(:author, :block_version)
        @suggestions = params[:sort] == "newest" ? @suggestions.order(created_at: :desc, id: :desc) : @suggestions.order(likes_count: :desc, created_at: :desc, id: :desc)
        @suggestion = @suggestions.find_by(id: params[:suggestion]) if params[:suggestion].present?
      end

      def select_mode!
        @mode = %w(comments suggestions edit).include?(params[:mode]) ? params[:mode] : "comments"
        @mode = "suggestions" if @suggestion && @mode != "edit"
        raise Decidim::ActionForbidden if @mode == "edit" && (!current_user || (@suggestion && !@suggestion.editable_by?(current_user)))
      end
    end
  end
end
