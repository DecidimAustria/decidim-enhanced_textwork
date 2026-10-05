# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module AdminLog
      class DocumentPresenter < Decidim::Log::BasePresenter
        private

        def action_string = "decidim.textwork.admin_log.#{action}"
      end
    end
  end
end
