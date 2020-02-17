require "aws-sdk-sqs"
require "json"
require "logger"
require "securerandom"
require "set"

require "soda/tools"

require "soda/client"
require "soda/fetcher"
require "soda/logger"
require "soda/manager"
require "soda/middleware/chain"
require "soda/processor"
require "soda/queue"
require "soda/queues/registry"
require "soda/retrier"
require "soda/worker"

module Soda
  NAME = "Soda"
  DEFAULTS = {
    concurrency: 10,
  }

  class << self
    def logger
      @logger ||= Soda::Logger.new(STDOUT)
    end

    def options
      @options ||= DEFAULTS.dup
    end

    def configure_server
      yield(self) if server?
    end

    def configure_client
      yield(self) unless server?
    end

    def server?
      defined?(Soda::CLI)
    end

    def sqs
      (@sqs ||= Aws::SQS::Client.new).tap do |client|
        yield(client) if block_given?
      end
    end

    def sqs=(options)
      @sqs_options = options || {}
      @sqs         = Aws::SQS::Client.new(@sqs_options)
    end

    def sqs_options
      @sqs_options ||= {}
    end

    def queues
      (@queues ||= Queues::Registry.new).tap do |registry|
        yield(registry) if block_given?
      end
    end

    def queue(name)
      queues.select(name).tap do |queue|
        yield(queue) if block_given?
      end
    end

    def default_queue!
      queues.default!
    end

    def client_middleware
      (@client_middleware ||= Middleware::Chain.new).tap do |chain|
        yield(chain) if block_given?
      end
    end

    def server_middleware
      (@server_middleware ||= Middleware::Chain.new).tap do |chain|
        yield(chain) if block_given?
      end
    end

    def dump_json(hash)
      JSON.dump(hash)
    end

    def load_json(str)
      JSON.load(str)
    end
  end
end
