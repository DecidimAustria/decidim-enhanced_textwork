# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
ENV["DECIDIM_AVAILABLE_LOCALES"] = "en,ca,es,de"

require "bundler/setup"
require File.join(ENV.fetch("TEXTWORK_TEST_APP", File.expand_path("decidim_dummy_app", __dir__)), "config/environment")
require "rspec/rails"
require "factory_bot_rails"
require "decidim/core/test/factories"
require_relative "support/factories"

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.include FactoryBot::Syntax::Methods
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.order = :random
  config.around { |example| I18n.with_locale(:en) { example.run } }
  config.before do
    ActiveJob::Base.queue_adapter = :test
  end
end
