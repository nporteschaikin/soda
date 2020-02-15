module Soda
  module Tools
    TID_KEY = :_soda_tid

    def logger
      ::Soda.logger
    end

    def sqs(&block)
      ::Soda.sqs(&block)
    end

    # h/t Sidekiq
    # https://github.com/mperham/sidekiq/blob/master/lib/sidekiq/logger.rb#L114
    def tid
      Thread.current[TID_KEY] ||= (Thread.current.object_id ^ ::Process.pid).to_s(36)
    end

    def now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
