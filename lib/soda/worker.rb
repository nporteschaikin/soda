module Soda
  module Worker
    class Options
      def initialize(klass, options)
        @klass    = klass
        @options  = options
      end

      def set(opts = {})
        tap do
          options.merge!(opts)
        end
      end

      def perform_async(*args)
        perform_in(0, *args)
      end

      def perform_in(delay, *args)
        tap do
          client = Soda::Client.new
          client.push(
            options.merge(
              "delay" => delay,
              "klass" => klass,
              "args"  => args,
            ),
          )
        end
      end
      alias_method :perform_at, :perform_in

      private

      attr_reader :klass, :options
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def set(opts = {})
        Options.new(self, options.merge(opts))
      end

      def soda_options(opts = {})
        options.merge!(opts)
      end

      def perform_async(*args)
        perform_in(0, *args)
      end

      def perform_in(delay, *args)
        tap do
          opts = Options.new(self, options)
          opts.perform_in(delay, *args)
        end
      end
      alias_method :perform_at, :perform_in

      private

      def options
        @options ||= {}
      end
    end

    def initialize(options = {})
      @options = options
    end

    %i[id].each do |method|
      define_method(method) do
        options.fetch(String(method))
      end
    end

    private

    attr_reader :options
  end
end
