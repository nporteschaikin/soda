require "spec_helper"

describe Soda::Client do
  class SodaClientStubWorker; end

  describe "#push" do
    around do |example|
      Soda.queues do |registry|
        registry.register("default")
        example.run
        registry.deregister("default")
      end
    end

    it "normalizes item" do
      item = {
        id: "foo",
        delay: "200",
        klass: SodaClientStubWorker,
      }

      expect_any_instance_of(Soda::Queue).to receive(:push_in) do |_, _, item|
        parsed = Soda.load_json(item)

        expect(parsed["id"].length).to eq(16)
        expect(parsed["delay"]).to be_a(Integer)
        expect(parsed["delay"]).to eq(200)
        expect(parsed["klass"]).to eq("SodaClientStubWorker")
        expect(parsed["queue"]).to eq("default")
      end

      described_class.new.push(item)
    end

    context "middleware" do
      class SodaClientStubMiddleware
        def call(_, item, *)
          item.merge!("foo" => "bar")
          yield
        end
      end

      around do |example|
        Soda.client_middleware do |chain|
          chain.add(SodaClientStubMiddleware)
          example.run
          chain.remove(SodaClientStubMiddleware)
        end
      end

      it "applies client middleware" do
        item = {
          "klass" => SodaClientStubWorker,
          "args"  => [],
          "delay" => 200,
        }

        expect_any_instance_of(Soda::Queue).to receive(:push_in) do |_, _, item|
          expect(Soda.load_json(item)["foo"]).to eq("bar")
        end

        described_class.new.push(item)
      end
    end
  end
end
