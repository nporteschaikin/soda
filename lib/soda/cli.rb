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

    DEFAULT_CONFIG = "config/soda.yml"

    def self.start
      new.run
    end

    def initialize(argv = ARGV)
      @argv = argv
    end

    def run
      build_options

      logger.info("🥤  %s v%s" % [Soda::NAME, Soda::VERSION])

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

      if File.exists?(default_config = File.expand_path(DEFAULT_CONFIG))
        opts[:config] ||= default_config
      end

      parse_config_file(opts, opts.delete(:config))

      if (req = opts.delete(:require))
        require(req)
      end

      if (queues = opts.delete(:queues))
        Soda.queues = queues
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
          name, weight = val.split(/,/)
          opts.merge!(queues: opts.fetch(:queues, []).push(name: name, weight: weight))
        end

        o.on("-c", "--concurrency [INT]", "Number of processor threads") do |val|
          opts.merge!(concurrency: Integer(val))
        end
      end
    end

    def parse_config_file(opts = {}, file)
      path = File.expand_path(file)

      unless File.exists?(path)
        raise "File does not exist: %s"
      end

      opts.merge!(
        deep_symbolize_keys(
          YAML.load(
            ERB.new(File.read(path)).result,
          ),
        ),
      )
    end

    def rails?
      require "rails"
      defined?(::Rails)
    rescue LoadError
      false
    end
  end
end
