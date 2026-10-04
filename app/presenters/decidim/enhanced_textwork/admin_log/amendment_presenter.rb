# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module AdminLog
      class AmendmentPresenter < Decidim::Log::BasePresenter
        private

        def action_string
          "decidim.enhanced_textwork.admin_log.amendment.#{action}"
        end
      end
    end
  end
end
