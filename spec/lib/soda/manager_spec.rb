require "spec_helper"

describe Soda::Manager do
  let(:queues) { Soda.queues }
  around(:each) do |example|
    begin
      opts = Soda.options
      count, opts[:concurrency] = opts[:concurrency], 5
      queues.register("q0")

      example.run

      queues.each do |queue|
        queues.deregister(queue.name)
      end
    ensure
      opts[:concurrency] = count
    end
  end

  describe "#initialize" do
    it "creates processors for each desired thread" do
      mgr = described_class.new
      workers = mgr.workers

      expect(workers.count).to eq(5)
    end
  end

  describe "#on_died" do
    it "replaces dead processor" do
      mgr = described_class.new
      workers = mgr.workers
      worker = workers.first
      count = workers.count

      expect(mgr.workers.count).to eq(count)
      mgr.on_died(worker)
      expect(mgr.workers).to_not include(worker)
      expect(mgr.workers.count).to eq(count)
    end
  end
end
