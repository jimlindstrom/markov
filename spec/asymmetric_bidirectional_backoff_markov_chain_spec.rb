#!/usr/bin/env ruby

require "spec_helper"

describe Markov::AsymmetricBidirectionalBackoffMarkovChain do
  let(:alphabet1) { Markov::LiteralAlphabet.new((1..1).to_a) }
  let(:alphabet2) { Markov::LiteralAlphabet.new((1..2).to_a) }
  let(:alphabet3) { Markov::LiteralAlphabet.new((1..3).to_a) }
  let(:alphabet4) { Markov::LiteralAlphabet.new((1..4).to_a) }
  let(:alphabet5) { Markov::LiteralAlphabet.new((1..5).to_a) }
  let(:alphabet90) { Markov::LiteralAlphabet.new((1..90).to_a) }

  context "new" do
    it "builds a chain with an order (# of current/past states used to predict the future) of 2 or greater" do
      Markov::AsymmetricBidirectionalBackoffMarkovChain.new(alphabet3, order=2, lookahead=1, num_states=5).should be_an_instance_of Markov::AsymmetricBidirectionalBackoffMarkovChain
    end
    it "raises an error for an order of 0 or lower" do
      expect{ Markov::AsymmetricBidirectionalBackoffMarkovChain.new(alphabet3, order=1, lookahead=1, num_states=5) }.to raise_error(ArgumentError)
    end
    it "builds a chain with two or more states" do
      Markov::AsymmetricBidirectionalBackoffMarkovChain.new(alphabet3, order=2, lookahead=1, num_states=2).should be_an_instance_of Markov::AsymmetricBidirectionalBackoffMarkovChain
    end
    it "raises an error for fewer than 2 states" do
      expect{ Markov::AsymmetricBidirectionalBackoffMarkovChain.new(alphabet3, order=2, lookahead=1, num_states=1) }.to raise_error(ArgumentError)
    end
    it "builds a chain with lookahead of one or more" do
      Markov::AsymmetricBidirectionalBackoffMarkovChain.new(alphabet3, order=2, lookahead=1, num_states=2).should be_an_instance_of Markov::AsymmetricBidirectionalBackoffMarkovChain
    end
    it "raises an error for less than 1 lookahead" do
      expect{ Markov::AsymmetricBidirectionalBackoffMarkovChain.new(alphabet3, order=2, lookahead=0, num_states=3) }.to raise_error(ArgumentError)
    end
  end

  context "current_state" do
    it "returns nil if in the initial state" do
      mc = Markov::AsymmetricBidirectionalBackoffMarkovChain.new(alphabet3, order=2, lookahead=1, num_states=2)
      mc.current_state.should equal nil
    end
    it "returns the current state" do
      mc = Markov::AsymmetricBidirectionalBackoffMarkovChain.new(alphabet3, order=2, lookahead=1, num_states=2)
      mc.transition(state=0, steps_left=1)
      mc.current_state.should equal 0
    end
  end

  context "steps_left" do
    it "returns nil if unknown" do
      mc = Markov::AsymmetricBidirectionalBackoffMarkovChain.new(alphabet3, order=2, lookahead=1, num_states=2)
      mc.steps_left.should be_nil
    end
    it "returns nil if more steps are left than the lookahead" do
      mc = Markov::AsymmetricBidirectionalBackoffMarkovChain.new(alphabet3, order=2, lookahead=2, num_states=2)
      mc.transition(state=1, steps_left=4)
      mc.steps_left.should be_nil
    end
    it "returns the number of steps left if 0..(lookahead-1) steps left" do
      mc = Markov::AsymmetricBidirectionalBackoffMarkovChain.new(alphabet3, order=2, lookahead=4, num_states=2)
      mc.transition(state=1, steps_left=1)
      mc.steps_left.should equal 1
    end
  end

  context "order" do
    it "returns the number of historical states the chain uses to predict future states" do
      mc = Markov::AsymmetricBidirectionalBackoffMarkovChain.new(alphabet3, order=2, lookahead=1, num_states=3)
      mc.order.should == 2
    end
  end

  context "reset" do
    it "resets the state back to the initial state (undoes do_transitions)" do
      mc = Markov::AsymmetricBidirectionalBackoffMarkovChain.new(alphabet3, order=2, lookahead=1, num_states=2)
      mc.transition(state=0, steps_left=5)
      mc.reset
      mc.current_state.should be_nil
    end
  end

  context "save" do
    it "saves the markov chain to a file" do
      mc = Markov::AsymmetricBidirectionalBackoffMarkovChain.new(alphabet3, order=2, lookahead=1, num_states=2)
      mc.transition(state=1, steps_left=7)
      mc.transition(state=1, steps_left=6)
      mc.transition(state=0, steps_left=5)
      filename = "/tmp/rubymidi_markov_chain.yml"
      mc.save filename
      File.exists?(filename).should == true
    end
  end

  context "load" do
    it "loads the markov chain to a file" do
      mc = Markov::AsymmetricBidirectionalBackoffMarkovChain.new(alphabet4, order=2, lookahead=1, num_states=20)
      mc.observe(outcome=1, steps_left=7)
      mc.transition(state=1, steps_left=7)
      mc.observe(outcome=2, steps_left=6)
      mc.transition(state=2, steps_left=6)
      mc.observe(outcome=3, steps_left=6)
      mc.transition(state=3, steps_left=5)
      mc.reset
      mc.transition(state=2, steps_left=7)
      filename = "/tmp/rubymidi_markov_chain.yml"
      mc.save filename
      mc2 = Markov::AsymmetricBidirectionalBackoffMarkovChain.load filename
      x = mc2.get_expectations
      x.sample.should == 3
    end
    it "restores the order proprely" do
      mc = Markov::AsymmetricBidirectionalBackoffMarkovChain.new(alphabet4, order=2, lookahead=1, num_states=20)
      filename = "/tmp/rubymidi_markov_chain.yml"
      mc.save filename
      mc2 = Markov::AsymmetricBidirectionalBackoffMarkovChain.load filename
      mc2.order.should == mc.order
    end
    it "restores the lookahead proprely" do
      mc = Markov::AsymmetricBidirectionalBackoffMarkovChain.new(alphabet4, order=2, lookahead=7, num_states=20)
      filename = "/tmp/rubymidi_markov_chain123.yml"
      mc.save filename
      mc2 = Markov::AsymmetricBidirectionalBackoffMarkovChain.load filename
      mc2.lookahead.should == mc.lookahead
    end
  end

  context "observe" do
    it "raises an error if the state is outside the 0..(num_outcomes-1) range" do
      mc = Markov::AsymmetricBidirectionalBackoffMarkovChain.new(alphabet3, order=2, lookahead=1, num_states=2)
      expect{ mc.observe(outcome=num_outcomes, steps_left=3) }.to raise_error
    end
    it "adds an observation of the next symbol" do
      mc = Markov::AsymmetricBidirectionalBackoffMarkovChain.new(alphabet3, order=2, lookahead=1, num_states=2)
      mc.observe(outcome=num_states, steps_left=6)
      mc.current_state.should equal nil
    end
    it "does not update state" do
      mc = Markov::AsymmetricBidirectionalBackoffMarkovChain.new(alphabet3, order=2, lookahead=1, num_states=2)
      mc.transition(state=1, steps_left=5)
      mc.observe(num_states, steps_left=4)
      mc.current_state.should equal 1
    end
  end

  context "transition" do
    it "raises an error if the state is outside the 0..(num_states-1) range" do
      mc = Markov::AsymmetricBidirectionalBackoffMarkovChain.new(alphabet3, order=2, lookahead=1, num_states=2)
      expect{ mc.transition(state=num_states, steps_left=5) }.to raise_error(ArgumentError)
    end
    it "does not add an observation of the next symbol" do
      mc = Markov::AsymmetricBidirectionalBackoffMarkovChain.new(alphabet3, order=2, lookahead=1, num_states=2)
      mc.transition(state=1, steps_left=8)
      mc.reset
      mc.get_expectations.sample.should be_nil
    end
    it "changes the state" do
      mc = Markov::AsymmetricBidirectionalBackoffMarkovChain.new(alphabet3, order=2, lookahead=1, num_states=2)
      mc.transition(state=1, steps_left=9)
      mc.current_state.should equal 1
    end
  end

  context "get_expectations" do
    it "returns a random variable" do
      mc = Markov::AsymmetricBidirectionalBackoffMarkovChain.new(alphabet3, order=2, lookahead=1, num_states=2)
      mc.get_expectations.should be_an_instance_of Markov::RandomVariable
    end
    it "returns a random variable that is less surprised about states observed more often" do
      mc = Markov::AsymmetricBidirectionalBackoffMarkovChain.new(alphabet5, order=2, lookahead=1, num_states=2)
      mc.observe(outcome=4, steps_left=6)
      mc.observe(outcome=4, steps_left=6)
      mc.observe(outcome=0, steps_left=6)
      x = mc.get_expectations
      x.surprise_for(4).should be < x.surprise_for(0)
    end
    it "returns a random variable that only chooses states observed" do
      mc = Markov::AsymmetricBidirectionalBackoffMarkovChain.new(alphabet5, order=2, lookahead=1, num_states=2)
      mc.observe(outcome=4, steps_left=2)
      x = mc.get_expectations
      x.sample.should == 4
    end
    it "isn't surprised by repeated substrings in a long string" do
      mc = Markov::AsymmetricBidirectionalBackoffMarkovChain.new(alphabet90, order=2, lookahead=1, num_states=100)
      pitches = [64, 71, 71, 69, 76, 74, 73, 71, 74, 73, 71, 73, 74, 73, 71, 73, 71] #, 73
      steps_left = 50 # some dummy value sufficiently high that we won't ever hit the last step
      pitches.each do |pitch|
        mc.observe(outcome=pitch, steps_left)
        mc.transition(state=pitch, steps_left)
        steps_left -= 1
      end
      x = mc.get_expectations
      x.surprise_for(73).should be < 0.5
    end
    it "returns returns expectations from lower-order predictions in novel situations" do
      mc = Markov::AsymmetricBidirectionalBackoffMarkovChain.new(alphabet90, order=8, lookahead=1, num_states=100)

      pitches = [66, 70, 71, 72, 73]
      steps_left = 50 # some dummy value sufficiently high that we won't ever hit the last step
      pitches.each do |pitch|
        mc.observe(outcome=pitch, steps_left)
        mc.transition(state=pitch, steps_left)
        steps_left -= 1
      end

      mc.reset

      pitches = [55, 70, 71, 72] #, 73
      steps_left = 50 # some dummy value sufficiently high that we won't ever hit the last step
      pitches.each do |pitch|
        mc.observe(outcome=pitch, steps_left)
        mc.transition(state=pitch, steps_left)
        steps_left -= 1
      end

      x = mc.get_expectations
      x.sample.should == 73
    end
  end

end
