# frozen_string_literal: true

require_relative "lib/decidim/enhanced_textwork/version"

Gem::Specification.new do |spec|
  spec.name = "decidim-enhanced_textwork"
  spec.version = Decidim::EnhancedTextwork.version
  spec.authors = ["Alexander Rusa"]
  spec.email = ["alex@rusa.at"]
  spec.license = "AGPL-3.0-or-later"
  spec.homepage = "https://github.com/DecidimAustria/decidim-enhanced_textwork"
  spec.summary = "Independent participatory documents, paragraph discussions and amendments for Decidim"
  spec.required_ruby_version = "~> 3.4.0"
  spec.files = Dir["{app,config,lib,db}/**/*", "bin/*", "README.md", "CHANGELOG.md", "docs/**/*.md"]

  spec.add_dependency "decidim-admin", Decidim::EnhancedTextwork.compat_decidim_version
  spec.add_dependency "decidim-comments", Decidim::EnhancedTextwork.compat_decidim_version
  spec.add_dependency "decidim-core", Decidim::EnhancedTextwork.compat_decidim_version
  spec.add_dependency "kramdown", "~> 2.5"
  spec.add_dependency "rubyzip", "~> 2.3"
end
