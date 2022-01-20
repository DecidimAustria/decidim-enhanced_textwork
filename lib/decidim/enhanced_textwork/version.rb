# frozen_string_literal: true

module Decidim
  # This holds decidim-paragraphs version.
  module EnhancedTextwork
    def self.version
      "1.0.0"
    end

    def self.compat_decidim_version 
      [">= 0.25", "<=0.26"].freeze
    end
  end
end
