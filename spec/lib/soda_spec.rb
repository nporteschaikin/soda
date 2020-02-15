require "spec_helper"

describe Soda do
  describe "JSON handling" do
    it "works" do
      expect(Soda.dump_json("foo" => "bar")).to eq(%({"foo":"bar"}))
      expect(Soda.load_json(%({"foo":"bar"}))).to eq("foo" => "bar")
    end
  end

  describe "env config" do
    it "only applies in server context" do
      allow(Soda).to receive(:server?).and_return(true)

      Soda.configure_server do |config|
        config.options[:foo] = "baz"
      end

      Soda.configure_client do |config|
        config.options[:foo] = "bar"
      end

      expect(Soda.options[:foo]).to eq("baz")
    end
  end
end
