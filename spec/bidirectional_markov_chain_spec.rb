#!/usr/bin/env ruby

require "spec_helper"

describe Markov::BidirectionalMarkovChain do
  let(:alphabet1) { Markov::LiteralAlphabet.new((1..1).to_a) }
  let(:alphabet2) { Markov::LiteralAlphabet.new((1..2).to_a) }
  let(:alphabet3) { Markov::LiteralAlphabet.new((1..3).to_a) }
  let(:alphabet4) { Markov::LiteralAlphabet.new((1..4).to_a) }
  let(:alphabet5) { Markov::LiteralAlphabet.new((1..5).to_a) }
  let(:alphabet90) { Markov::LiteralAlphabet.new((1..90).to_a) }

  it_should_behave_like "a bidirectional markov chain" do
    def params_for_new(output_alphabet, order, lookahead)
      [output_alphabet, order, lookahead]
    end
  end

  describe "#new" do
    subject { described_class.new(alphabet5, order=1, lookahead=3) }
    it { should be_an_instance_of described_class }
    it "raises an error for an order of 0 or lower" do
      expect{ described_class.new(alphabet5, order=0, lookahead=2) }.to raise_error(ArgumentError)
    end
    it "raises an error if not looking ahead 1 or more steps" do
      expect{ described_class.new(alphabet2, order=1, lookahead=0) }.to raise_error(ArgumentError)
    end
  end

  describe "#load" do
    context "given that another MC has been saved" do
      let(:filename) { "/tmp/rubymidi_bidirectional_markov_chain.json" }
      before(:all) do
        mc = described_class.new(alphabet90, order=1, lookahead=1)
        [1,3,1,2].each_with_index do |x, i|
          mc.observe!(   state=x, steps_left=3-i)
          mc.transition!(state=x, steps_left=3-i)
        end
        mc.reset!
        mc.transition!(state=1, steps_left=1)
        mc.save filename
      end
      subject { described_class.load filename }
      it { should be_an_instance_of described_class }
      it "should restore the state of the original MC" do
       subject.expectations.sample.should == 2
      end
    end
  end

  describe ".expectations" do
    it "returns a random variable that only chooses states observe!d (higher order)" do
      mc = described_class.new(alphabet5, order=2, lookahead=1)
      [1,2,4].each_with_index do |x, i|
        mc.observe!(   state=x, steps_left=5-i)
        mc.transition!(state=x, steps_left=5-i)
      end
      mc.reset!
      [4,2,3].each_with_index do |x, i|
        mc.observe!(   state=x, steps_left=5-i)
        mc.transition!(state=x, steps_left=5-i)
      end
      mc.reset!
      [4,2].each_with_index do |x, i|
        mc.transition!(state=x, steps_left=5-i)
      end
      mc.expectations.sample.should == 3
    end
    it "returns a random variable that only chooses states observe!d with the same steps remaining" do
      mc = described_class.new(alphabet5, order=1, lookahead=1)
      [1,3,1,2].each_with_index do |x, i|
        mc.observe!(   state=x, steps_left=3-i)
        mc.transition!(state=x, steps_left=3-i)
      end
      mc.reset!
      mc.transition!(state=1, steps_left=1)
      mc.expectations.sample.should == 2
    end
  end

end
