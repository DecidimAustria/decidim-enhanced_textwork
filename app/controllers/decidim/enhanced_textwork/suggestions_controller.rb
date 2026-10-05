# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class SuggestionsController < ApplicationController
      before_action :authenticate_user!, except: [:show, :index]
      def index = redirect_to(document_path(published_document))

      def show
        suggestion = Suggestion.where(block: published_document.blocks).find(params[:id])
        redirect_to document_path(published_document, block: suggestion.block_id, suggestion: suggestion.id)
      end

      def create = save_suggestion

      def update = save_suggestion

      def withdraw
        suggestion = Suggestion.listed.where(block: published_document.blocks.active).find(params[:id])
        WithdrawSuggestion.call(suggestion, current_user) do
          on(:ok) { render json: { block: suggestion.block_id, message: I18n.t("decidim.textwork.withdrawn") } }
          on(:forbidden) { head :forbidden }
        end
      end

      private

      def save_suggestion
        block = published_document.blocks.active.find(params[:block_id])
        suggestion = block.suggestions.listed.find(params[:id]) if params[:id]
        SaveSuggestion.call(block, current_user, body: params[:body].to_s, justification: params[:justification].to_s,
                                                 expected_version: params[:expected_version], suggestion:) do
          on(:ok) { |record| render json: { block: block.id, suggestion: record.id, message: I18n.t("decidim.textwork.submitted") } }
          on(:invalid) { |record| render json: { error: record.errors.full_messages.join(". ") }, status: :unprocessable_content }
          on(:conflict) { render json: { error: I18n.t("decidim.textwork.conflict") }, status: :conflict }
          on(:forbidden) { head :forbidden }
        end
      end
    end
  end
end
