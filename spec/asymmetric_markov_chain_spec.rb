#!/usr/bin/env ruby

require "spec_helper"

describe Markov::AsymmetricMarkovChain do
  let(:alphabet1) { Markov::LiteralAlphabet.new((1..1).to_a) }
  let(:alphabet2) { Markov::LiteralAlphabet.new((1..2).to_a) }
  let(:alphabet90) { Markov::LiteralAlphabet.new((1..90).to_a) }

  it_should_behave_like "a simple markov chain" do
    let(:other_params) { [num_states=20] }
  end

  describe "#new" do
    it "raises an error for fewer than 2 states" do
      expect{ described_class.new(alphabet1, order=1, num_states=1) }.to raise_error(ArgumentError)
    end
  end

  describe ".transition" do
    let(:num_states) { 3 }
    subject { described_class.new(alphabet2, order=1, num_states) }
    it "raises an error if the state is outside the 0..(num_symbols-1) range" do
      expect{ subject.transition(num_states) }.to raise_error(ArgumentError)
    end
  end

  describe "#load" do
    it "loads the markov chain to a file" do
      mc = Markov::AsymmetricMarkovChain.new(alphabet90, order=1, num_states=20)
      mc.observe(1)
      mc.transition(1)
      mc.observe(2)
      mc.transition(2)
      mc.observe(3)
      mc.transition(3)
      mc.reset
      mc.transition(2)
      filename = "/tmp/rubymidi_markov_chain.yml"
      mc.save filename
      mc2 = Markov::AsymmetricMarkovChain.load filename
      x = mc2.expectations
      x.sample.should == 3
    end
  end

  describe ".expectations" do
    it "returns a random variable" do
      mc = Markov::AsymmetricMarkovChain.new(alphabet2, order=1, num_states=2)
      mc.expectations.should be_an_instance_of Markov::RandomVariable
    end
    it "returns a random variable that is less surprised about states observed more often" do
      mc = Markov::AsymmetricMarkovChain.new(alphabet90, order=1, num_states=2)
      mc.observe(4)
      mc.observe(4)
      mc.observe(0)
      x = mc.expectations
      x.surprise_for(4).should be < x.surprise_for(0)
    end
    it "returns a random variable that only chooses states observed" do
      mc = Markov::AsymmetricMarkovChain.new(alphabet90, order=1, num_states=2)
      mc.observe(4)
      x = mc.expectations
      x.sample.should == 4
    end
    it "returns a random variable that only chooses states observed (higher order)" do
      mc = Markov::AsymmetricMarkovChain.new(alphabet90, order=2, num_states=5)
      mc.observe(1)
      mc.transition(1)
      mc.observe(2)
      mc.transition(2)
      mc.observe(4)
      mc.transition(4)
      mc.reset
      mc.observe(0)
      mc.transition(0)
      mc.observe(2)
      mc.transition(2)
      mc.observe(3)
      mc.transition(3)
      mc.reset
      mc.transition(0)
      mc.transition(2)
      x = mc.expectations
      x.sample.should == 3
    end
    it "isn't surprised by repeated substrings in a long string" do
      mc = Markov::AsymmetricMarkovChain.new(alphabet90, order=2, num_states=100)
      pitches = [64, 71, 71, 69, 76, 74, 73, 71, 74, 73, 71, 73, 74, 73, 71, 73, 71] #, 73
      pitches.each do |pitch|
        mc.observe(outcome=pitch)
        mc.transition(state=pitch)
      end
      x = mc.expectations
      x.surprise_for(outcome=73).should be < 0.5
    end
  end

end
