#!/usr/bin/env ruby

require "spec_helper"

describe Markov::AsymmetricBidirectionalBackoffMarkovChain do
  let(:alphabet1) { Markov::LiteralAlphabet.new((1..1).to_a) }
  let(:alphabet2) { Markov::LiteralAlphabet.new((1..2).to_a) }
  let(:alphabet90) { Markov::LiteralAlphabet.new((1..90).to_a) }

  it_should_behave_like "a bidirectional markov chain" do
    def params_for_new(output_alphabet, order, lookahead)
      [output_alphabet, output_alphabet, order, lookahead]
    end
  end

  describe "#new" do
    subject { described_class.new(alphabet2, alphabet2, order=2, lookahead=1) }
    it { should be_an_instance_of described_class }
    context "when order <= 0" do
      it "raises an error" do
        expect{ described_class.new(alphabet1, alphabet2, order=1, lookahead=1) }.to raise_error(ArgumentError)
      end
    end
    context "when lookahead < 1" do
      it "raises an error" do
        expect{ described_class.new(alphabet90, alphabet2, order=2, lookahead=0) }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#load" do
    let(:mc) { Markov::AsymmetricBidirectionalBackoffMarkovChain.new(alphabet90, alphabet90, order=2, lookahead=1) }
    context "when a MC has been saved" do
      let(:filename) { "/tmp/rubymidi_markov_chain.json" }
      before(:all) do
        [1,2,3].each_with_index do |x, i|
          mc.observe!(   state=x, steps_left=7-i)
          mc.transition!(state=x, steps_left=7-i)
        end
        mc.reset!
        mc.transition!(state=1, steps_left=7)
        mc.transition!(state=2, steps_left=6)
        mc.save filename
      end
      subject { Markov::AsymmetricBidirectionalBackoffMarkovChain.load filename }
      it { should be_an_instance_of described_class }
      specify { subject.expectations.sample.should == 3 }
      its(:order)     { should == mc.order }
      its(:lookahead) { should == mc.lookahead }
    end
  end

  describe ".expectations" do
    it "isn't surprised by repeated substrings in a long string" do
      mc = Markov::AsymmetricBidirectionalBackoffMarkovChain.new(alphabet90, alphabet90, order=2, lookahead=1)
      pitches = [64, 71, 71, 69, 76, 74, 73, 71, 74, 73, 71, 73, 74, 73, 71, 73, 71] #, 73
      steps_left = 50 # some dummy value sufficiently high that we won't ever hit the last step
      pitches.each do |pitch|
        mc.observe!(outcome=pitch, steps_left)
        mc.transition!(state=pitch, steps_left)
        steps_left -= 1
      end
      x = mc.expectations
      x.surprise_for(73).should be < 0.5
    end
    context "when the same substring (shorter than the order) has been observe!d 2x with a different prefix" do
      let(:mc) { described_class.new(alphabet90, alphabet90, order=8, lookahead=1) }
      let(:expected_next_val) { 73 }
      before do
        random_prefix1 = [66]
        common_suffix = [70, 71, 72]
        pitches1 = random_prefix1 + common_suffix + [expected_next_val]

        random_prefix2 = [25]
        pitches2 = random_prefix2 + common_suffix

        steps_left = 50 # some dummy value sufficiently high that we won't ever hit the last step

        pitches1.each_with_index do |pitch, i|
          mc.observe!( outcome=pitch, steps_left-i)
          mc.transition!(state=pitch, steps_left-i)
        end
        mc.reset!
        pitches2.each_with_index do |pitch, i|
          mc.observe!( outcome=pitch, steps_left-i)
          mc.transition!(state=pitch, steps_left-i)
        end
      end
      it "correctly identifies the next value (using lower-order predictions)" do
        mc.expectations.sample.should == expected_next_val
      end
    end
  end

end
