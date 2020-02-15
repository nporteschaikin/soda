module Soda
  class Fetcher
    # If there's an error fetching from a queue, we should sleep.
    SLEEP = 10

    include Tools

    # Uses a weighted round robin approach to selecting which queue to use.
    # See: https://en.wikipedia.org/wiki/Weighted_round_robin
    def initialize
      @mutex  = Mutex.new
      @queues = weigh_queues
      @paused = []
    end

    def fetch
      unpause

      queue = next!
      if queue
        msgs = pop(queue)
        msgs.tap do
          pause(queue, queue.options[:sleep]) if msgs.count.zero?
        end
      end
    rescue Aws::SQS::Errors::ServiceError
      pause(queue, SLEEP) unless queue.nil?

      raise
    end

    private unless $TESTING

    attr_reader :queues, :paused, :mutex

    def pop(queue)
      start = now
      logger.debug(%(fetching from "%s") % queue.name)

      queue.pop.tap do |msgs|
        logger.debug(%(fetched %d message(s) from "%s" (%fms)) % [msgs.count, queue.name, (now - start)])
      end
    end

    def next!
      mutex.synchronize do
        queues.shift.tap do |q|
          queues.push(q) unless q.nil?
        end
      end
    end

    def unpause
      mutex.synchronize do
        paused.each do |wakeup, q|
          if wakeup <= Time.now
            paused.delete([wakeup, q])
            queues.concat(weigh_queues([q]))

            logger.info(%(un-paused fetching from "%s") % q.name)
          end
        end
      end
    end

    def pause(queue, sleep)
      mutex.synchronize do
        if queues.delete(queue)
          paused << [Time.now + sleep, queue]
          logger.info(%(paused fetching from "%s" for %d second(s)) % [queue.name, sleep])
        end
      end
    end

    def weigh_queues(queues = Soda.queues)
      [].tap do |weighted|
        queues.each do |queue|
          weighted.concat([queue] * queue.weight)
        end
      end
    end
  end
end
