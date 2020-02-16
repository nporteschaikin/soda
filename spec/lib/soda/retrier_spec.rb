require "spec_helper"

describe Soda::Retrier do
  describe "#retry" do
    let(:item) do
      {
        "klass" => "HardJob",
        "args"  => [],
        "retry" => true,
      }
    end

    let(:attributes) do
      {
        Soda::Queue::FIRST_RECEIVED_AT_ATTRIBUTE => Time.now.to_i * 1_000,
        Soda::Queue::RECEIVE_COUNT_ATTRIBUTE => 1,
      }
    end

    let(:queue) { Soda::Queue.new("foo", "https://queue.sqs") }

    let(:msg) do
      Soda::Queue::Message.new(
        queue,
        double(
          body: Soda.dump_json(item),
          receipt_handle: "receipt",
          attributes: attributes,
        ),
      )
    end

    it "updates visibility timeout" do
      freeze_time do
        retrier = described_class.new

        expect(Soda.sqs).to receive(:change_message_visibility).with(
          queue_url:          queue.url,
          receipt_handle:     msg.receipt,
          visibility_timeout: (Time.now - msg.first_received_at).to_i + (msg.receive_count ** 2),
        )

        begin
          retrier.retry(item, msg) { raise }
        rescue
        end
      end
    end

    context "retry is false" do
      let(:item) do
        {
          "klass" => "HardJob",
          "args"  => [],
          "retry" => false,
        }
      end

      it "does not update timeout" do
        retrier = described_class.new

        expect(Soda.sqs).to_not receive(:change_message_visibility)

        begin
          retrier.retry(item, msg) { raise }
        rescue
        end
      end
    end

    context "retry is nil" do
      let(:item) do
        {
          "klass" => "HardJob",
          "args"  => [],
        }
      end

      it "does not update timeout" do
        retrier = described_class.new

        expect(Soda.sqs).to_not receive(:change_message_visibility)

        begin
          retrier.retry(item, msg) { raise }
        rescue
        end
      end
    end

    context "retries exceeded" do
      let(:item) do
        {
          "klass" => "HardJob",
          "args"  => [],
          "retry" => 5,
        }
      end

      let(:attributes) do
        {
          Soda::Queue::FIRST_RECEIVED_AT_ATTRIBUTE => Time.now.to_i * 1_000,
          Soda::Queue::RECEIVE_COUNT_ATTRIBUTE => 5,
        }
      end

      it "does not update timeout" do
        retrier = described_class.new

        expect(Soda.sqs).to_not receive(:change_message_visibility)

        begin
          retrier.retry(item, msg) { raise }
        rescue
        end
      end
    end

    context "max timeout exceeded" do
      let(:attributes) do
        {
          Soda::Queue::FIRST_RECEIVED_AT_ATTRIBUTE => (Time.now.to_i - described_class::MAX_TIMEOUT) * 1_000,
          Soda::Queue::RECEIVE_COUNT_ATTRIBUTE => 1,
        }
      end

      it "does not update timeout" do
        retrier = described_class.new

        expect(Soda.sqs).to_not receive(:change_message_visibility)

        begin
          retrier.retry(item, msg) { raise }
        rescue
        end
      end
    end
  end
end
