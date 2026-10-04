# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
ENV["DECIDIM_AVAILABLE_LOCALES"] = "en,ca,es,de"

require "bundler/setup"
require_relative "decidim_dummy_app/config/environment"
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
  config.before do
    I18n.locale = :en
    ActiveJob::Base.queue_adapter = :test
  end
end
