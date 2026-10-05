# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class VersionsController < ApplicationController
      include Decidim::ResourceVersionsConcern

      helper Decidim::EnhancedTextwork::ReadingHelper
      def index
        @archived_comments = versioned_resource.comments.not_hidden.not_deleted.order(:created_at) if versioned_resource.removed?
        @archived_suggestions = versioned_resource.suggestions.listed.order(:created_at) if versioned_resource.removed?
      end

      private

      def versioned_resource
        @versioned_resource ||= published_document.blocks.find(params[:block_id])
      end
    end
  end
end
