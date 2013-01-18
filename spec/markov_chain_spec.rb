#!/usr/bin/env ruby

require "spec_helper"

describe Markov::MarkovChain do
  let(:alphabet1) { Markov::LiteralAlphabet.new((1..1).to_a) }
  let(:alphabet2) { Markov::LiteralAlphabet.new((1..2).to_a) }
  let(:alphabet90) { Markov::LiteralAlphabet.new((1..90).to_a) }

  it_should_behave_like "a simple markov chain" do
    let(:other_params) { [] }
  end

  describe "#load" do
    context "when a MarkovChain has been saved" do
      before(:all) do
        @mc = Markov::MarkovChain.new(alphabet90, order=1)
        [1, 2, 3].each do |x|
          @mc.observe(x)
          @mc.transition(x)
        end
        @mc.reset
        @mc.transition(2)
        @filename = "/tmp/rubymidi_markov_chain.yml"
        @mc.save @filename
      end
      it "loads the markov chain to a file" do
        mc2 = Markov::MarkovChain.load @filename
        mc2.expectations.sample.should == @mc.expectations.sample
      end
    end
  end

  describe ".expectations" do
    context "given a 1st order chain" do
      subject { Markov::MarkovChain.new(alphabet90, order=1) }
      its(:expectations) { should be_an_instance_of Markov::RandomVariable }
      context "given some observations" do
        before(:each) do
          2.times { subject.observe(1) }
          1.times { subject.observe(0) }
        end
        it "returns a random variable that is less surprised about states observed more often" do
          subject.expectations.surprise_for(1).should be <  subject.expectations.surprise_for(0)
        end
        it "returns a random variable that only chooses states observed" do
          [0, 1].should include(subject.expectations.sample)
        end
      end
    end

    context "given a 2nd order chain" do
      subject { Markov::MarkovChain.new(alphabet90, order=2) }
      it "returns a random variable that only chooses states observed" do
        [1, 2, 4].each do |x|
          subject.observe(x)
          subject.transition(x)
        end
        subject.reset
        [0, 2, 3].each do |x|
          subject.observe(x)
          subject.transition(x)
        end
        subject.reset
        [0, 2].each do |x|
          subject.transition(x)
        end
        subject.expectations.sample.should == 3
      end
      it "isn't surprised by repeated substrings in a long string" do
        pitches = [64, 71, 71, 69, 76, 74, 73, 71, 74, 73, 71, 73, 74, 73, 71, 73, 71] #, 73
        pitches.each do |pitch|
          subject.observe(pitch)
        end
        subject.expectations.surprise_for(73).should be < 0.5
      end
    end
  end

end
