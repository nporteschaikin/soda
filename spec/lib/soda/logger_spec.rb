require "spec_helper"

describe Soda::Logger do
  let(:output) { StringIO.new }
  subject(:logger) { described_class.new(output) }

  around do |example|
    example.run
    output.truncate(0)
    output.rewind
  end

  describe "#with" do
    it "adds context" do
      logger.with([:foo, "bar"]) do
        logger.info("hello!")
      end

      expect(output.string).to match(/foo: bar/)
      expect(output.string).to match(/hello!/)
    end
  end

  describe Soda::Logger::JobLogger do
    let(:parent) { Soda::Logger.new(output) }
    subject(:logger) { described_class.new(parent) }

    describe "#with" do
      it "adds job context, start, and finish" do
        logger.with("klass" => "ExampleJob", "id" => "foo") do
          parent.info("hello!")
        end

        lines = output.string.split("\n")
        expect(lines.count).to eq(3)

        lines.each do |line|
          expect(line).to match(/worker: ExampleJob/)
          expect(line).to match(/jid: foo/)
        end

        expect(lines[0]).to match(/start/)
        expect(lines[1]).to match(/hello!/)
        expect(lines[2]).to match(/finish/)
        expect(lines[2]).to match(/ms/)
      end
    end
  end
end
