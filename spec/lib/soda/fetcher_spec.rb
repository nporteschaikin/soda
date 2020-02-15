require "spec_helper"

describe Soda::Fetcher do
  let(:queues) { Soda.queues }
  around(:each) do |example|
    example.run

    queues.each do |queue|
      queues.deregister(queue.name)
    end
  end

  describe "pausing" do
    it "does not pause if any messages are returned" do
      allow_any_instance_of(Soda::Queue).to receive(:pop).and_return([1])

      queues.register("q0")

      fetcher = described_class.new

      fetcher.fetch {}
      expect(fetcher.next!.name).to eq("q0")
    end

    it "pauses if no messages are returned" do
      allow_any_instance_of(Soda::Queue).to receive(:pop).and_return([])

      queues.register("q0")

      fetcher = described_class.new

      fetcher.fetch {}
      expect(fetcher.next!).to eq(nil)
    end
  end

  describe "#next!" do
    it "gets queues in order by weight" do
      queues.register("q0", weight: 1)
      queues.register("q1", weight: 4)
      queues.register("q2", weight: 2)

      fetcher = described_class.new
      expect(fetcher.next!.name).to eq("q0")

      4.times do
        expect(fetcher.next!.name).to eq("q1")
      end

      2.times do
        expect(fetcher.next!.name).to eq("q2")
      end
    end
  end
end
