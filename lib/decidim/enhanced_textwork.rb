# frozen_string_literal: true

require "decidim/core"
require "decidim/comments"
require "decidim/enhanced_textwork/version"
require "decidim/enhanced_textwork/engine"
require "decidim/enhanced_textwork/admin_engine"
require "decidim/enhanced_textwork/component"
module Decidim
  module EnhancedTextwork
    def self.enabled?(component)
      component&.manifest_name == "textwork"
    end
  end
end
