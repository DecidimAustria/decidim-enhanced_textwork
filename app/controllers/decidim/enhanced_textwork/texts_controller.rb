# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class TextsController < Decidim::Proposals::ApplicationController
      helper Decidim::Proposals::ApplicationHelper
      helper Decidim::EnhancedTextwork::TextsHelper

      def show
        raise ActionController::RoutingError, "Not Found" unless Decidim::EnhancedTextwork.enabled?(current_component)

        @document = Decidim::Proposals::ParticipatoryText.find_by(component: current_component)
        @paragraphs = Decidim::Proposals::Proposal.where(component: current_component)
                                                .published.not_hidden.only_amendables
                                                .includes(:component, :proposal_state)
                                                .order(:position, :id)
        @active_paragraph = @paragraphs.find(params[:paragraph_id]) if params[:paragraph_id].present?
      end
    end
  end
end
