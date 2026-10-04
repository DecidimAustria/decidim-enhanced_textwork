# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      class ApplicationController < Decidim::Admin::Components::BaseController
        before_action :authorize_textwork
        helper Decidim::EnhancedTextwork::TextsHelper

        private

        def authorize_textwork
          enforce_permission_to :manage, :textwork
        end

        def document
          @document ||= Document.find_by!(component: current_component)
        end
      end
    end
  end
end
