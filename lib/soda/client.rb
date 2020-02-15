module Soda
  class Client
    def push(item)
      copy  = normalize!(item)
      mw    = Soda.client_middleware

      mw.use(item["klass"], copy, copy["queue"]) do
        Soda.queue(copy["queue"]) do |queue|
          queue.push_in(copy["delay"], Soda.dump_json(copy))
        end
      end
    end

    private

    def normalize!(item)
      item.dup.tap do |copy|
        copy.keys.each do |key|
          copy.merge!(String(key) => copy[key])
        end

        id      = SecureRandom.base64(10)
        klass   = copy["klass"].to_s
        delay   = Integer(copy["delay"]) || 0
        queue   = copy["queue"] || Soda.default_queue!.name

        # TODO: add validation
        #
        copy.merge!(
          "id"    => id,
          "klass" => klass,
          "delay" => delay,
          "queue" => queue,
        )
      end
    end
  end
end
