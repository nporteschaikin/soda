module Soda
  class Manager
    attr_reader :fetcher

    def initialize
      @workers  = Set.new
      @fetcher  = Fetcher.new
      @mutex    = Mutex.new
      @shutdown = false

      count = Soda.options[:concurrency]
      count.times do
        @workers << Processor.new(self)
      end
    end

    def start
      workers.each(&:start)
    end

    def stop
      shutdown!

      workers.each(&:stop)
      workers.each(&:finish)
    end

    # A processor will die on failed job execution. Replace it with a new one.
    def on_died(worker)
      mutex.synchronize do
        workers.delete(worker)

        unless shutdown?
          workers << (processor = Processor.new(self))

          processor.start
        end
      end
    end

    private unless $TESTING

    attr_reader :workers, :mutex

    def shutdown!
      @shutdown = true
    end

    def shutdown?
      @shutdown
    end
  end
end
