# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module ProposalsControllerExtension
      def index
        return super unless Decidim::EnhancedTextwork.enabled?(current_component)

        redirect_to Decidim::EngineRouter.main_proxy(current_component).textwork_path
      end
    end
  end
end
