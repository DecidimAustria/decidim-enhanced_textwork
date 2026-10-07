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
        load_stats
      end

      def statistics
        @document = published_document
        load_stats
        render json: { counts: @stats.counts, numbers: @stats.numbers, chapters: @stats.chapter_counts,
                       summary: @stats.summary, summary_text: I18n.t("decidim.textwork.documents.show.summary", **@stats.summary) }
      end

      def panel
        @document = published_document
        load_stats
        @block = @blocks.find { |block| block.id.to_s == params[:block] }
        @block ||= @document.blocks.find_by(id: params[:block]) if params[:block].present?
        return render(partial: "overview") unless @block&.paragraph?
        return render partial: "unavailable", locals: { removed: true } if @block.removed?

        load_suggestions
        return render(partial: "unavailable", locals: { removed: false }) if params[:suggestion].present? && !@suggestion

        select_mode!

        render partial: "panel"
      end

      def history
        raise Decidim::ActionForbidden unless Access.evaluation_enabled?(current_component)

        @document = published_document
        @history = (@document.document_revisions.includes(:author,
                                                          :block).to_a + BlockVersion.where(block: @document.blocks).includes(:author, :block).to_a).sort_by(&:created_at).reverse
      end

      private

      def load_stats
        @document.component = current_component
        @stats = DocumentStats.new(@document, current_user)
        @blocks = @stats.blocks
        @numbers = @stats.numbers
      end

      def load_suggestions
        @suggestions = @block.suggestions.not_hidden.where(status: "pending").includes(:author).order(likes_count: :desc, created_at: :asc, id: :asc)
        @suggestion = @suggestions.find_by(id: params[:suggestion]) if params[:suggestion].present?
      end

      def editor_access? = current_user && (!@suggestion || @suggestion.editable_by?(current_user))

      def select_mode!
        @mode = params[:mode] == "edit" ? "edit" : "list"
        @mode = "detail" if @suggestion && @mode != "edit"
        raise Decidim::ActionForbidden if @mode == "edit" && !editor_access?
        raise Decidim::ActionForbidden if @mode == "edit" && !Participation.open?(current_component, :suggestions)
      end
    end
  end
end
