#!/usr/bin/env ruby

require "spec_helper"

describe Markov::AsymmetricMarkovChain do
  let(:alphabet1) { Markov::LiteralAlphabet.new((1..1).to_a) }
  let(:alphabet2) { Markov::LiteralAlphabet.new((1..2).to_a) }
  let(:alphabet90) { Markov::LiteralAlphabet.new((1..90).to_a) }

  it_should_behave_like "a simple markov chain" do
    def params_for_new(output_alphabet, order)
      [output_alphabet, output_alphabet, order]
    end
  end

  describe ".transition!" do
    subject { described_class.new(alphabet2, alphabet2, order=1) }
    context "when the input_symbol isn't in the input alphabet" do
      let(:invalid_input_symbol) { 100 }
      it "raises an error" do
        expect{ subject.transition!(invalid_input_symbol) }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#load" do
    it "loads the markov chain to a file" do
      mc = Markov::AsymmetricMarkovChain.new(alphabet90, alphabet90, order=1)
      mc.observe!(1)
      mc.transition!(1)
      mc.observe!(2)
      mc.transition!(2)
      mc.observe!(3)
      mc.transition!(3)
      mc.reset!
      mc.transition!(2)
      filename = "/tmp/rubymidi_markov_chain.json"
      mc.save filename
      mc2 = Markov::AsymmetricMarkovChain.load filename
      x = mc2.expectations
      x.sample.should == 3
    end
  end

  describe ".expectations" do
    it "returns a random variable" do
      mc = Markov::AsymmetricMarkovChain.new(alphabet2, alphabet2, order=1)
      mc.expectations.should be_an_instance_of Markov::RandomVariable
    end
    it "returns a random variable that is less surprised about states observe!d more often" do
      mc = Markov::AsymmetricMarkovChain.new(alphabet90, alphabet90, order=1)
      mc.observe!(4)
      mc.observe!(4)
      mc.observe!(2)
      x = mc.expectations
      x.surprise_for(4).should be < x.surprise_for(2)
    end
    it "returns a random variable that only chooses states observe!d" do
      mc = Markov::AsymmetricMarkovChain.new(alphabet90, alphabet90, order=1)
      mc.observe!(4)
      x = mc.expectations
      x.sample.should == 4
    end
    it "returns a random variable that only chooses states observe!d (higher order)" do
      mc = Markov::AsymmetricMarkovChain.new(alphabet90, alphabet90, order=2)
      mc.transition!(1)
      mc.transition!(2)
      mc.observe!(4)
      mc.reset!
      mc.transition!(9)
      mc.transition!(2)
      mc.observe!(3)
      mc.reset!
      mc.transition!(9)
      mc.transition!(2)
      x = mc.expectations
      x.sample.should == 3
    end
    it "isn't surprised by repeated substrings in a long string" do
      mc = Markov::AsymmetricMarkovChain.new(alphabet90, alphabet90, order=2)
      pitches = [64, 71, 71, 69, 76, 74, 73, 71, 74, 73, 71, 73, 74, 73, 71, 73, 71] #, 73
      pitches.each do |pitch|
        mc.observe!(output_symbol=pitch)
        mc.transition!(input_symbol=pitch)
      end
      x = mc.expectations
      x.surprise_for(outcome=73).should be < 0.5
    end
  end

end
