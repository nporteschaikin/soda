require "spec_helper"

describe Soda::Processor do
  let(:mgr) { Soda::Manager.new }
  subject(:processor) { described_class.new(mgr) }

  class SodaProcessorStubJob
    include Soda::Worker

    def perform(str); end
  end

  around(:each) do |example|
    Soda.queues do |registry|
      registry.register("q0", "https://queue.sqs")
      example.run
      registry.deregister("q0")
    end
  end

  describe "#process" do
    let(:msg) do
      Soda::Queue::Message.new(
        Soda.queues.select("q0"),
        double(
          body: Soda.dump_json("klass" => "SodaProcessorStubJob", "args" => ["foo"]),
          receipt_handle: "receipt",
        ),
      )
    end

    it "works" do
      expect_any_instance_of(SodaProcessorStubJob).to receive(:perform).with("foo")
      processor.process(msg)
    end

    it "applies server middleware" do
      class SodaProcessorMiddlewareStub
        def call(_, item, *)
          item.merge!("foo" => "bar")
          yield
        end
      end

      expect(SodaProcessorStubJob).to receive(:new).with(hash_including("foo" => "bar")).
        and_return(double(perform: true))

      Soda.server_middleware do |chain|
        chain.add(SodaProcessorMiddlewareStub)
        processor.process(msg)
        chain.remove(SodaProcessorMiddlewareStub)
      end
    end

    context "invalid body" do
      let(:msg) do
        Soda::Queue::Message.new(
          Soda.queues.select("q0"),
          double(
            body: "++",
            receipt_handle: "receipt",
          ),
        )
      end

      it "acknowledges msg" do
        expect(msg).to receive(:acknowledge).and_return(true)
        processor.process(msg)
      end
    end

    context "missing required keys" do
      let(:msg) do
        Soda::Queue::Message.new(
          Soda.queues.select("q0"),
          double(
            body: Soda.dump_json("foo" => "bar"),
            receipt_handle: "receipt",
          ),
        )
      end

      it "acknowledges msg" do
        expect(msg).to receive(:acknowledge).and_return(true)
        processor.process(msg)
      end
    end
  end
end
