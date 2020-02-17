# Soda

[![Maintainability](https://api.codeclimate.com/v1/badges/f42ad155fd0d09c7960a/maintainability)](https://codeclimate.com/github/nporteschaikin/soda/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/f42ad155fd0d09c7960a/test_coverage)](https://codeclimate.com/github/nporteschaikin/soda/test_coverage)
![Run tests](https://github.com/nporteschaikin/soda/workflows/Run%20tests/badge.svg?branch=master)

A background job processor backed by [AWS SQS](https://aws.amazon.com/sqs/) queues and written in Ruby. Heavily inspired by [Sidekiq](https://github.com/mperham/sidekiq), a Redis-backed background processor.

## TOC

  * [Why?](#why)
  * [Getting started](#getting-started)
  * [Defining queues](#defining-queues)
  * [Configuration](#configuration)
  * [Alternatives](#alternatives)
  * [Acknowledgments](#acknowledgments)
  * [License](#license)

## Why?

Sidekiq is fantastic, as is Redis as a queue store. It's eminently flexible and easy to get working out of the box. Sidekiq is also a close-to-perfectly-crafted piece of code; in many ways, this project is my homage to Mike Perham's work.

I've wanted to write something like Sidekiq but for SQS for a while. I worked on a service which reads work off an SQS queue and enqueues the same work to Redis. It does this because we want to communicate with this service via SQS but Sidekiq is awesome. This is probably fine, but seems a little duplicative and adds the significant operational overhead of requiring a Redis instance. This inspired me to write a drop-in Sidekiq replacement that is backed by SQS. [For good reason](https://github.com/mperham/sidekiq/wiki/FAQ#wouldnt-it-be-awesome-if-sidekiq-supported-mongodb-postgresql-mysql-sqs--for-persistence), Mike isn't interested in offering an SQS-backed version of Sidekiq, so this is my attempt to fill that void.

This served as a fun opportunity to learn more about the mechanics of Sidekiq, so there's that.

## Getting started

Before proceeding, you'll need to create an SQS queue for storing work. In the future, I'll provide a CLI for creating Soda-optimized SQS queues. Until then, visit [AWS's SQS console](https://console.aws.amazon.com/sqs) and create a queue.

### Rails

1. Add soda to your `Gemfile`, specifying `require: "soda"`:

  ```ruby
  gem "soda-core", require: "soda"
  ```

2. Define a worker in `app/workers`:

  ```ruby
  class HardJob
    include Soda::Worker

    soda_options queue: "soda_queue"

    def perform(name, time)
      sleep(time)
      puts "#{name} is done!"
    end
  end
  ```

3. Enqueue a job:

  ```ruby
  HardJob.perform_async("Bob")

  # or, ask Soda to perform the work in two minutes:
  HardJob.perform_in(120, "Bob")
  ```

4. To process work, start Soda from the root of your Rails application:

  ```sh
  bundle exec soda
  ```

### Plain Ruby

1. Add soda to your `Gemfile`:

  ```ruby
  gem "soda-core"
  ```

2. In your application, require `soda` and define a worker:

  ```ruby
  # hard_job.rb

  require "soda"

  class HardJob
    include Soda::Worker

    soda_options queue: "soda_queue"

    def perform(name, time)
      sleep(time)
      puts "#{name} is done!"
    end
  end
  ```

3. Enqueue a job:

  ```ruby
  HardJob.perform_async("Bob")

  # or, ask Soda to perform the work in two minutes:
  HardJob.perform_in(120, "Bob")
  ```

4. Start Soda, requiring the entrypoint:

  ```shell
  bundle exec soda --require hard_job.rb
  ```

## Defining queues

Soda defines a configurable SQS queue registry to support convenient access to SQS queues from the client and the server.

To define a queue, add it to the queue registry on initialization:

```ruby
require "soda"

Soda.queues do |registry|
  registry.register("default")
end
```

The first defined queue becomes the default queue. If no queue is specified in a worker's `soda_options` or by using `Worker.set(queue: "queue")`, work is enqueued to the default queue.

Named queues can be defined to point to a specific URL:

```ruby
Soda.queues do |registry|
  registry.register("default", "https://sqs.region.amazonaws.com/account/name")
end
```

Additionally, queues can be defined with several options:

```ruby
Soda.queues do |registry|
  registry.register(
    "high",
    weight:   2,    # A queue with a weight of 2 is checked twice as often as a queue with a weight of 1.
    sleep:    10,   # If no messages are received for the queue on a fetch attempt, don't fetch from this queue for 10 seconds.
    wait:     10,   # How long to poll SQS per fetch attempt until a message is received.
                    # See: https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-short-and-long-polling.html#sqs-long-polling
    timeout:  25,   # Set the visibility timeout for messages received in a fetch request.
                    # See: https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html
  )
end
```

## Configuration

Coming soon; for now, see [soda.rb](lib/soda.rb) to get an idea of how to configure Soda. I'm going to add a YAML config option soon.

## Alternatives

[Shoryuken](https://github.com/phstc/shoryuken) is similar: it's also a drop-in Sidekiq replacement backed by SQS. It also has nearly 2,000 stars on GitHub and is a mature codebase. If those things mean a lot to you, use Shoryuken! I haven't tried it but I'm sure it's great software.

## Acknowledgments

As mentioned above, this work is largely influenced by [Sidekiq](https://github.com/mperham/sidekiq). To be honest, if you don't mind using Redis as your job store, then please use Sidekiq. It is fantastic software and Soda is certainly a less mature, less feature-rich, and generally less good option.

## License

See [LICENSE](LICENSE)
