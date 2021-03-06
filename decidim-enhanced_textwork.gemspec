# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "decidim/enhanced_textwork/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.version = Decidim::EnhancedTextwork.version
  s.authors = ["Alexander Rusa"]
  s.email = ["alex@rusa.at"]
  s.license = "AGPL-3.0"
  s.homepage = "https://github.com/DecidimAustria/decidim-enhanced_textwork"
  s.required_ruby_version = ">= 2.7"

  s.name = "decidim-enhanced_textwork"
  s.summary = "Decidim enhanced textwork module"
  s.description = "A text work component for decidim's participatory spaces."

  s.files = Dir["{app,config,db,lib}/**/*", "Rakefile", "README.md"]

  s.add_dependency "commonlit-caracal", "~> 1.7.2"
  s.add_dependency "decidim-comments", Decidim::EnhancedTextwork.compat_decidim_version
  s.add_dependency "decidim-core", Decidim::EnhancedTextwork.compat_decidim_version
  s.add_dependency "doc2text", "~> 0.4.3"
  s.add_dependency "redcarpet", "~> 3.5", ">= 3.5.1"

  s.add_dependency "docx", "~> 0.6.2"
  s.add_dependency "kramdown", "~> 2.3"

  s.add_development_dependency "decidim-admin", Decidim::EnhancedTextwork.compat_decidim_version
  s.add_development_dependency "decidim-assemblies", Decidim::EnhancedTextwork.compat_decidim_version
  s.add_development_dependency "decidim-budgets", Decidim::EnhancedTextwork.compat_decidim_version
  s.add_development_dependency "decidim-dev", Decidim::EnhancedTextwork.compat_decidim_version
  s.add_development_dependency "decidim-meetings", Decidim::EnhancedTextwork.compat_decidim_version
  s.add_development_dependency "decidim-participatory_processes", Decidim::EnhancedTextwork.compat_decidim_version
end
