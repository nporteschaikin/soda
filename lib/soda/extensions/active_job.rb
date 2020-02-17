module ActiveJob
  module QueueAdapters
    class SodaAdapter
      def enqueue(job)
        enqueue_at(job, Time.now)
      end

      def enqueue_at(job, ts)
        job.provider_job_id = ::Soda::Client.push(
          "klass"   => JobWrapper,
          "wrapped" => job.class,
          "queue"   => job.queue_name,
          "delay"   => [0, (ts - Time.now).to_i].max,
          "args"    => [job.serialize],
        )
      end

      class JobWrapper
        include ::Soda::Worker

        def perform(data = {})
          Base.execute(data.merge("provider_job_id" => id))
        end
      end
    end
  end
end
