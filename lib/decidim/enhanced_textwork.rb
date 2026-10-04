# frozen_string_literal: true

require "decidim/proposals"
require "decidim/enhanced_textwork/version"

module Decidim
  module EnhancedTextwork
    def self.enabled?(component)
      component&.manifest_name == "proposals" &&
        component.settings.participatory_texts_enabled? &&
        component.settings.enhanced_textwork_enabled?
    end
  end
end

require "decidim/enhanced_textwork/engine"
