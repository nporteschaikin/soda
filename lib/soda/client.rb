module Soda
  class Client
    DEFAULTS = {
      "retry" => true,
      "delay" => 0,
    }

    class << self
      def push(*args)
        new.push(*args)
      end
    end


    def push(item)
      copy = normalize!(item)

      mw = Soda.client_middleware
      mw.use(item["klass"], copy, copy["queue"]) do
        jid = copy["id"]
        jid.tap do
          queue = Soda.queue(copy["queue"])
          queue.push_in(copy["delay"], Soda.dump_json(copy))
        end
      end
    end

    private

    def normalize!(item)
      item = DEFAULTS.merge(item)
      item.tap do
        item.keys.each do |key|
          item.merge!(String(key) => item.delete(key))
        end

        id      = SecureRandom.base64(10)
        klass   = item["klass"].to_s
        delay   = item["delay"].to_i
        queue   = item["queue"] || Soda.default_queue!.name

        # TODO: add validation
        #
        item.merge!(
          "id"    => id,
          "klass" => klass,
          "delay" => delay,
          "queue" => queue,
        )
      end
    end
  end
end
