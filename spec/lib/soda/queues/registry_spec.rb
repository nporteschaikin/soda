require "spec_helper"

describe Soda::Queues::Registry do
  describe "#select" do
    describe "queue exists" do
      it "returns queue" do
        registry = described_class.new
        registry.register("test", "foo")

        queue = registry.select("test")

        expect(queue.name).to eq("test")
        expect(queue.url).to eq("foo")
      end
    end

    describe "queue missing" do
      it "creates queue" do
        registry = described_class.new

        queue = registry.select("test")
        expect(queue.name).to eq("test")
        expect(queue.url).to eq(nil)
      end
    end
  end

  describe "#register" do
    describe "queue exists" do
      it "replaces queue" do
        registry = described_class.new
        registry.register("test", "foo", weight: 6)
        registry.register("test", "bar", weight: 3)

        queue = registry.select("test")

        expect(queue.name).to eq("test")
        expect(queue.url).to eq("bar")
        expect(queue.weight).to eq(3)
      end
    end
  end
end
