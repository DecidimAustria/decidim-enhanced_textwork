# frozen_string_literal: true

module Decidim
  # This holds decidim-paragraphs version.
  module EnhancedTextwork
    def self.version
      "1.0.3"
    end

    def self.compat_decidim_version 
      [">= 0.26.0.rc2", "< 0.27"].freeze
    end
  end
end
