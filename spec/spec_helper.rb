require "simplecov"
SimpleCov.start

$TESTING = true

require "bundler/setup"
Bundler.setup

require "soda"

module Helpers
end

# Turn off logs
Soda.logger.level = 4

RSpec.configure do |config|
  config.before do
    Soda.sqs = { stub_responses: true }
  end
  config.include(Helpers)
end
