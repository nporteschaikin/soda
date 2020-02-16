require "spec_helper"

class StubSodaWorker
  include Soda::Worker

  soda_options queue: "foo", foo: "bar"
end

describe Soda::Worker do
  describe "set" do
    it "merges over class-level options" do
      expect_any_instance_of(Soda::Client).to receive(:push).
        with(hash_including(queue: "bar", foo: "bar"))

      StubSodaWorker.set(queue: "bar").
        set(queue: "foo").
        set(queue: "bar").
        perform_async
    end
  end

  describe "#perform_async" do
    it "pushes to client with no delay" do
      expect_any_instance_of(Soda::Client).to receive(:push).
        with(hash_including(queue: "foo", foo: "bar", "delay" => 0))

      StubSodaWorker.perform_async
    end
  end

  describe "#perform_in" do
    it "pushes to client with delay" do
      expect_any_instance_of(Soda::Client).to receive(:push).
        with(hash_including(queue: "foo", foo: "bar", "delay" => 10))

      StubSodaWorker.perform_in(10)
    end
  end
end
