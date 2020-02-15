module Soda
  class Logger < ::Logger
    class Formatter
      include Tools

      CONTEXT_KEY = :_soda_log_context

      def call(severity, time, _, message)
        context = format_context(severity, time)

        "%s %s\n" % [context, message]
      end

      def context
        Thread.current[CONTEXT_KEY] || []
      end

      def context=(ctx)
        Thread.current[CONTEXT_KEY] = ctx
      end

      private

      def format_context(severity, time)
        ctx   = [[:tid, tid]].concat(context)
        parts = ctx.map { |k, v| "[%s: %s]" % [k, v] }
        "[%s] %s %s" % [time.iso8601(3), parts.join(" "), severity]
      end
    end

    def initialize(*args, **kwargs)
      super

      self.formatter = Formatter.new
    end

    def with(*context)
      ctx, formatter.context =
        formatter.context, (formatter.context + context)

      yield
    ensure
      formatter.context = ctx
    end

    class JobLogger
      include Tools

      def initialize(logger = Soda.logger)
        @logger = logger
      end

      def with(job_hash)
        logger.with([:worker, job_hash["klass"]], [:jid, job_hash["id"]]) do
          start = now
          logger.info("start")

          yield

          logger.info("finish (%fms)" % (now - start))
        end
      end

      private

      attr_reader :logger
    end
  end
end
