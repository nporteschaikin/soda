require "optparse"

module Soda
  class CLI
    include Tools

    TERM = "TERM".freeze
    INT  = "INT".freeze

    SIGNALS = [
      TERM,
      INT,
    ].freeze

    def self.start
      new.run
    end

    def initialize(argv = ARGV)
      @argv = argv
    end

    def run
      build_options

      if rails?
        if Rails::VERSION::MAJOR >= 5
          require "./config/application.rb"
          require "./config/environment.rb"
          require "soda/rails"
          require "soda/extensions/active_job"

          logger.info("Loaded Rails v%s application." % ::Rails.version)
        else
          raise "Not compatible with Rails v%s!" % Rails.version
        end
      end

      manager = Manager.new
      manager.start

      read, write = IO.pipe

      SIGNALS.each do |signal|
        trap(signal) do
          write.puts(signal)
        end
      end

      logger.info("Starting up...")
      manager.start

      while (io = IO.select([read]))
        line, _ = io.first
        sig = line.gets.strip

        handle_signal(sig)
      end
    rescue Interrupt
      logger.info("Shutting down...")
      manager.stop
      logger.info("👋")

      exit(0)
    end

    private

    attr_reader :argv, :manager

    def handle_signal(signal)
      logger.info("Received signal %s..." % signal)

      case signal
      when TERM
      when INT
        raise Interrupt
      end
    end

    def build_options
      opts    = {}
      parser  = build_option_parser(opts)
      parser.parse!(argv)

      if (req = opts.delete(:require))
        require(req)
      end

      if (queues_opt = opts.delete(:queues))
        parse_queues(queues_opt)
      end

      options = Soda.options
      options.merge!(opts)
    end

    def build_option_parser(opts)
      OptionParser.new do |o|
        o.on("-r", "--require [PATH]", "Location of file to require") do |val|
          opts.merge!(require: val)
        end

        o.on("-q", "--queue QUEUE[,WEIGHT]", "Queue to listen to, with optional weights") do |val|
          opts.merge!(queues: opts.fetch(:queues, []).push(val.split(/\,+/)))
        end

        o.on("-c", "--concurrency [INT]", "Number of processor threads") do |val|
          opts.merge!(concurrency: Integer(val))
        end
      end
    end

    def parse_queues(opt)
      Soda.queues do |registry|
        opt.each do |name, weight|
          # Find or create the queue.
          queue = registry.select(name)

          if weight
            # Replace the queue with the same one, except mutate the options to
            # include the specified weight.
            registry.register(
              queue.name,
              queue.url,
              queue.options.merge(weight: weight.to_i),
            )
          end
        end

        # For queues that are not included in the command, set their weight to
        # zero so they can still be accessed.
        names = opt.map(&:first)
        registry.each do |queue|
          unless names.include?(queue.name)
            registry.register(
              queue.name,
              queue.url,
              queue.options.merge(weight: 0),
            )
          end
        end
      end
    end

    def rails?
      require "rails"
      defined?(::Rails)
    rescue LoadError
      false
    end
  end
end
