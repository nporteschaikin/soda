# Soda

A background job processor backed by [AWS SQS](https://aws.amazon.com/sqs/) queues and written in Ruby. Heavily inspired by Sidekiq, a Redis-backed background processor.

## TOC

  * [Why?](#why)
  * [Getting started](#getting-started)
  * [Configuration](#configuration)
  * [Alternatives](#alternatives)

## Why?

Sidekiq is fantastic, as is Redis as a queue store. It's eminently flexible and easy to get working out of the box.

## Getting started

#### Rails

1. Add soda to your `Gemfile`:

  ```ruby
  gem "soda"
  ```

2. Define a worker:

  ```ruby
  class HardJob
    include Soda::Worker

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
