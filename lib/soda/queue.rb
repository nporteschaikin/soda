module Soda
  class Queue
    include Tools

    Message = Struct.new(:queue, :contents) do
      include Tools

      FIRST_RECEIVED_AT_ATTRIBUTE = "ApproximateFirstReceiveTimestamp".freeze
      RECEIVE_COUNT_ATTRIBUTE     = "ApproximateReceiveCount".freeze

      def receipt; contents.receipt_handle; end
      def str;     contents.body; end

      def first_received_at
        int = contents.attributes[FIRST_RECEIVED_AT_ATTRIBUTE]
        Time.at(int.to_f / 1_000)
      end

      def receive_count
        contents.attributes[RECEIVE_COUNT_ATTRIBUTE].to_i
      end

      # This is a bit of an inference: if we've received the message more than
      # one, we can assume it's a retry. This is useful for handling batches.
      def retry?
        receive_count > 1
      end

      def acknowledge
        sqs do |client|
          logger.with([:receipt, receipt]) do
            client.delete_message(
              queue_url:      queue.lazy_url,
              receipt_handle: receipt,
            )

            logger.debug("acknowleged")
          end
        end
      end
    end

    attr_reader :name, :url, :options

    DEFAULTS = {
      weight:   1,
      sleep:    1,
      wait:     1,
      timeout:  25,
    }

    def initialize(name, url, options = {})
      @name     = name
      @url      = url
      @options  = DEFAULTS.dup.merge(options)
    end

    %i[weight sleep wait timeout].each do |method|
      define_method(method) do
        options.fetch(method)
      end
    end

    # Lazily fetch queue URL if one is not provided as part of the queue
    # configuration.
    def lazy_url
      @lazy_url ||=
        url || begin
          resp = sqs.get_queue_url(queue_name: name)
          resp.queue_url
        end
    end

    def push_in(interval, str)
      sqs do |client|
        client.send_message(
          queue_url:      lazy_url,
          message_body:   str,
          delay_seconds:  interval,
        )
      end
    end

    def pop
      resp = sqs.receive_message(
        queue_url:               lazy_url,
        attribute_names:         %w[All],
        message_attribute_names: %w[All],
        wait_time_seconds:       wait,
        visibility_timeout:      timeout,
      )

      Enumerator.new do |yielder|
        resp.messages.each do |msg|
          yielder.yield(Message.new(self, msg))
        end
      end
    end

    def ==(other)
      other.name == name
    end
  end
end
