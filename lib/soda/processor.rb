module Soda
  class Processor
    include Tools

    def initialize(manager)
      @manager      = manager
      @retrier      = Retrier.new
      @job_logger   = Soda::Logger::JobLogger.new
      @stopped      = false
    end

    def start
      @thread ||= Thread.new(&method(:run))
    end

    def stop
      @stopped = true
    end

    def finish
      thread.join
    end

    private unless $TESTING

    attr_reader :manager, :retrier, :job_logger, :thread

    def stopped?
      @stopped
    end

    def run
      until stopped?
        msgs = fetch
        msgs.each(&method(:process))
      end
    rescue Exception => ex
      manager.on_died(self)
    end

    def fetch
      fetcher = manager.fetcher
      fetcher.fetch
    rescue => ex
      handle_exception(ex)

      raise
    end

    def process(msg)
      if (job_hash = parse_job(msg.str))
        job_logger.with(job_hash) do
          execute(job_hash, msg)
        end
      else
        # We can't process the work because the JSON is invalid, so we have to
        # acknowledge the message (thus removing it) and move on.
        msg.acknowledge
      end
    rescue => ex
      handle_exception(ex)

      raise
    end

    def execute(job_hash, msg)
      queue   = msg.queue
      klass   = job_hash["klass"]
      worker  = constantize(klass)

      retrier.retry(job_hash, msg) do
        middleware = Soda.server_middleware
        middleware.use(worker, job_hash, queue.name, msg) do
          instance = worker.new(job_hash)
          instance.perform(*job_hash["args"])
        end

        msg.acknowledge
      end
    end

    def parse_job(str)
      Soda.load_json(str).tap do |job_hash|
        # ensure the JSON has an `args` and a `klass` value before considering
        # the message valid.
        job_hash.fetch("klass") && job_hash.fetch("args")
      end
    rescue => ex
      nil
    end

    # For now, don't do much - just log out the error
    # TODO: make this more robust. Maybe support error handlers.
    def handle_exception(ex)
      logger.error(ex)
    end

    def constantize(str)
      Object.const_get(str)
    end
  end
end
