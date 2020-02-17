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

    def deep_symbolize_keys(hash)
      transform_value = -> (value) {
        case value
        when Hash
          deep_symbolize_keys(value)
        when Array
          value.map { |val| transform_value.call(val) }
        else
          value
        end
      }

      {}.tap do |memo|
        hash.each do |key, value|
          memo.merge!(key.to_sym => transform_value.call(value))
        end
      end
    end
  end
end
