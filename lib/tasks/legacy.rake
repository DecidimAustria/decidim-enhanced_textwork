# frozen_string_literal: true

namespace :decidim_enhanced_textwork do
  namespace :legacy do
    desc "Report legacy Textwork records without changing them (no text or personal data)"
    task inspect: :environment do
      require "json"
      require "decidim/enhanced_textwork/legacy_inventory"

      puts JSON.pretty_generate(Decidim::EnhancedTextwork::LegacyInventory.new(ActiveRecord::Base.connection).report)
    end
  end
end
