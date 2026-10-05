# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class BlocksController < ApplicationController
      def index = redirect_to(document_path(published_document))

      def show
        block = published_document.blocks.find(params[:id])
        redirect_to document_path(published_document, block: block.id)
      end
    end
  end
end
