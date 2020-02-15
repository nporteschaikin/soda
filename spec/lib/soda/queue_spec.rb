require "spec_helper"

describe Soda::Queue do
  subject(:queue) { described_class.new("foo1", "https://foo.sqs") }

  describe "#lazy_url" do
    it "returns defined URL" do
      expect(queue.lazy_url).to eq("https://foo.sqs")
    end

    context "no URL defined" do
      subject(:queue) { described_class.new("foo1", nil) }

      it "looks up URL once" do
        expect(Soda.sqs).to receive(:get_queue_url).once.and_return(
          double(
            queue_url: "foo",
          ),
        )
        expect(queue.lazy_url).to eq("foo")
      end
    end
  end

  describe "#eq?" do
    it "only considers name" do
      expect(queue == described_class.new("foo1", nil)).to eq(true)
      expect(queue == described_class.new("foo1", "meow")).to eq(true)
      expect(queue == described_class.new("foo2", nil)).to eq(false)
    end
  end
end
