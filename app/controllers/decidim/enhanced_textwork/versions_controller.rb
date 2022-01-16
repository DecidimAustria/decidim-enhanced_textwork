# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    # Exposes Paragraphs versions so users can see how a Paragraph/CollaborativeDraft
    # has been updated through time.
    class VersionsController < Decidim::EnhancedTextwork::ApplicationController
      include Decidim::ApplicationHelper
      include Decidim::ResourceVersionsConcern

      def versioned_resource
        @versioned_resource ||=
          if params[:paragraph_id]
            present(Paragraph.where(component: current_component).find(params[:paragraph_id]))
          else
            CollaborativeDraft.where(component: current_component).find(params[:collaborative_draft_id])
          end
      end
    end
  end
end
