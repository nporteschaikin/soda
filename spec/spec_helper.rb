require "simplecov"
SimpleCov.start

$TESTING = true

require "bundler/setup"
Bundler.setup

require "soda"

module Helpers
  def freeze_time(time = Time.now)
    allow(Time).to receive(:now).and_return(time)
    allow(Date).to receive(:today).and_return(time.to_date)

    yield

    allow(Time).to receive(:now).and_call_original
    allow(Date).to receive(:today).and_call_original
  end
end

# Turn off logs
Soda.logger.level = 4

RSpec.configure do |config|
  config.before do
    Soda.sqs = { stub_responses: true }
  end
  config.include(Helpers)
end
