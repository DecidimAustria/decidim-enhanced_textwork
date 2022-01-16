# frozen_string_literal: true

base_path = File.expand_path("..", __dir__)

Decidim::Webpacker.register_path("#{base_path}/app/packs")
Decidim::Webpacker.register_entrypoints(
  decidim_enhanced_textwork: "#{base_path}/app/packs/entrypoints/decidim_enhanced_textwork.js",
  decidim_enhanced_textwork_admin: "#{base_path}/app/packs/entrypoints/decidim_enhanced_textwork_admin.js"
)
Decidim::Webpacker.register_stylesheet_import("stylesheets/decidim/enhanced_textwork/paragraphs")
