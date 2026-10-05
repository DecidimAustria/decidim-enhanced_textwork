# frozen_string_literal: true

source "https://rubygems.org"

ruby "~> 3.4.0"
gemspec

# Set this only when testing against a local Decidim checkout.
if ENV["DECIDIM_PATH"]
  Dir[File.join(ENV.fetch("DECIDIM_PATH"), "{,decidim-*/}*.gemspec")].each do |spec_file|
    spec = Gem::Specification.load(spec_file)
    gem spec.name, path: File.dirname(spec_file)
  end
else
  gem "decidim", "~> 0.32.1"
  gem "decidim-dev", "~> 0.32.1"
end

gem "bootsnap", "~> 1.23"
gem "puma", ">= 6.3.1"
