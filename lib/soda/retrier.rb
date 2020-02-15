module Soda
  class Retrier
    include Tools

    # AWS enforces a 12-hour maximum visibility timeout. If this is surpassed,
    # the job is dead.
    MAX_TIMEOUT = 60 * 60 * 12

    def retry(job_hash, msg)
      yield
    rescue => ex
      if postpone?(job_hash, msg)
        postpone(msg)
      end

      raise
    end

    private

    def postpone?(job_hash, msg)
      ret = job_hash["retry"]

      if ret.is_a?(Numeric)
        ret < msg.receive_count
      else
        ret
      end
    end

    def postpone(msg)
      sqs do |client|
        timeout =
          (Time.now - msg.first_received_at).to_i + (msg.receive_count ** 2)

        if timeout <= MAX_TIMEOUT
          client.change_message_visibility(
            queue_url:          msg.queue.lazy_url,
            receipt_handle:     msg.receipt,
            visibility_timeout: timeout,
          )
        else
          # This is not going to work; delete from the queue and move on. Bye
          # for good!
          msg.acknowledge
        end
      end
    end
  end
end
