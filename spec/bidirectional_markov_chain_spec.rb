#!/usr/bin/env ruby

require "spec_helper"

describe Markov::BidirectionalMarkovChain do
  let(:alphabet1) { Markov::LiteralAlphabet.new((1..1).to_a) }
  let(:alphabet2) { Markov::LiteralAlphabet.new((1..2).to_a) }
  let(:alphabet3) { Markov::LiteralAlphabet.new((1..3).to_a) }
  let(:alphabet4) { Markov::LiteralAlphabet.new((1..4).to_a) }
  let(:alphabet5) { Markov::LiteralAlphabet.new((1..5).to_a) }
  let(:alphabet90) { Markov::LiteralAlphabet.new((1..90).to_a) }

  context "new" do
    it "builds a chain with an order (# of current/past states used to predict the future) of 1 or greater" do
      Markov::BidirectionalMarkovChain.new(alphabet5, order=1, lookahead=3, num_states=5).should be_an_instance_of Markov::BidirectionalMarkovChain
    end
    it "raises an error for an order of 0 or lower" do
      expect{ Markov::BidirectionalMarkovChain.new(alphabet5, order=0, lookahead=2, num_states=5) }.to raise_error(ArgumentError)
    end
    it "builds a chain with two or more states" do
      Markov::BidirectionalMarkovChain.new(alphabet2, order=1, lookahead=2, num_states=2).should be_an_instance_of Markov::BidirectionalMarkovChain
    end
    it "raises an error for fewer than 2 states" do
      expect{ Markov::BidirectionalMarkovChain.new(alphabet1, order=1, lookahead=1, num_states=1) }.to raise_error(ArgumentError)
    end
    it "raises an error if not looking ahead 1 or more steps" do
      expect{ Markov::BidirectionalMarkovChain.new(alphabet2, order=1, lookahead=0, num_states=2) }.to raise_error(ArgumentError)
    end
  end

  context "current_state" do
    it "returns nil if in the initial state" do
      mc = Markov::BidirectionalMarkovChain.new(alphabet2, order=1, lookahead=1, num_states=2)
      mc.current_state.should be_nil
    end
    it "returns the current state" do
      mc = Markov::BidirectionalMarkovChain.new(alphabet2, order=1, lookahead=1, num_states=2)
      mc.transition(state=0, steps_left=1)
      mc.current_state.should == 0
    end
  end

  context "steps_left" do
    it "returns nil if unknown" do
      mc = Markov::BidirectionalMarkovChain.new(alphabet2, order=1, lookahead=1, num_states=2)
      mc.steps_left.should be_nil
    end
    it "returns nil if more steps are left than the lookahead" do
      mc = Markov::BidirectionalMarkovChain.new(alphabet2, order=1, lookahead=2, num_states=2)
      mc.transition(state=1, steps_left=4)
      mc.steps_left.should be_nil
    end
    it "returns the number of steps left if 0..(lookahead-1) steps left" do
      mc = Markov::BidirectionalMarkovChain.new(alphabet2, order=1, lookahead=4, num_states=2)
      mc.transition(state=1, steps_left=1)
      mc.steps_left.should == 1
    end
  end

  context "order" do
    it "returns the number of historical states the chain uses to predict future states" do
      mc = Markov::BidirectionalMarkovChain.new(alphabet3, order=1, lookahead=2, num_states=3)
      mc.order.should == 1
    end
  end

  context "lookahead" do
    it "returns the number of steps the chain will look ahead to plan for the terminal state" do
      mc = Markov::BidirectionalMarkovChain.new(alphabet3, order=1, lookahead=2, num_states=3)
      mc.lookahead.should == 2
    end
  end

  context "reset" do
    it "resets the state back to the initial state (undoes do_transitions)" do
      mc = Markov::BidirectionalMarkovChain.new(alphabet2, order=1, lookahead=1, num_states=2)
      mc.transition(state=0, steps_left=0)
      mc.reset
      mc.current_state.should be_nil
      mc.steps_left.should be_nil
    end
  end

  context "save" do
    it "saves the markov chain to a file" do
      mc = Markov::BidirectionalMarkovChain.new(alphabet2, order=1, lookahead=1, num_states=2)
      mc.observe(state=1, steps_left=2)
      mc.observe(state=1, steps_left=2)
      mc.observe(state=0, steps_left=2)
      filename = "/tmp/rubymidi_bidirectional_markov_chain.yml"
      mc.save filename
      File.exists?(filename).should == true
    end
  end

  context "load" do
    it "loads the markov chain to a file" do
      mc = Markov::BidirectionalMarkovChain.new(alphabet90, order=1, lookahead=1, num_states=20)
      mc.observe(   state=1, steps_left=3)
      mc.transition(state=1, steps_left=3)
      mc.observe(   state=3, steps_left=2)
      mc.transition(state=3, steps_left=2)
      mc.observe(   state=1, steps_left=1)
      mc.transition(state=1, steps_left=1)
      mc.observe(   state=2, steps_left=0)
      mc.transition(state=2, steps_left=0)
      mc.reset
      mc.transition(state=1, steps_left=1)
      filename = "/tmp/rubymidi_bidirectional_markov_chain.yml"
      mc.save filename
      mc2 = Markov::BidirectionalMarkovChain.load filename
      x = mc2.get_expectations
      x.sample.should == 2
    end
  end

  context "observe" do
    it "raises an error if the state is outside the 0..(num_states-1) range" do
      mc = Markov::BidirectionalMarkovChain.new(alphabet2, order=1, lookahead=1, num_states=2)
      expect{ mc.observe(state=num_states, steps_left=2) }.to raise_error(ArgumentError)
    end
    it "raises an error if the number of steps left is less than zero" do
      mc = Markov::BidirectionalMarkovChain.new(alphabet2, order=1, lookahead=1, num_states=2)
      expect{ mc.observe(state=1, steps_left=-1) }.to raise_error(ArgumentError)
    end
    it "raises an error if steps_left is !nil and the observed steps_left is not exactly one less" do
      mc = Markov::BidirectionalMarkovChain.new(alphabet2, order=1, lookahead=5, num_states=2)
      mc.transition(state=1, steps_left=3)
      expect{ mc.observe(state=1, steps_left=1) }.to raise_error(ArgumentError)
    end
    it "adds an observation of the next symbol" do
      mc = Markov::BidirectionalMarkovChain.new(alphabet2, order=1, lookahead=1, num_states=2)
      mc.observe(state=0, steps_left=1)
      pending
    end
    it "does not update state" do
      mc = Markov::BidirectionalMarkovChain.new(alphabet2, order=1, lookahead=4, num_states=2)
      mc.transition(state=1, steps_left=1)
      mc.observe(state=0, steps_left=0)
      mc.current_state.should == 1
    end
    it "does not update steps_left" do
      mc = Markov::BidirectionalMarkovChain.new(alphabet2, order=1, lookahead=4, num_states=2)
      mc.transition(state=1, steps_left=1)
      mc.observe(state=0, steps_left=0)
      mc.steps_left.should == 1
    end
  end

  context "transition" do
    it "raises an error if the state is outside the 0..(num_states-1) range" do
      mc = Markov::BidirectionalMarkovChain.new(alphabet2, order=1, lookahead=1, num_states=2)
      expect{ mc.transition(state=num_states, steps_left=3) }.to raise_error(ArgumentError)
    end
    it "does not add an observation of the next symbol" do
      mc = Markov::BidirectionalMarkovChain.new(alphabet2, order=1, lookahead=1, num_states=2)
      mc.transition(state=1, steps_left=3)
      mc.reset
      mc.get_expectations.sample.should be_nil
    end
    it "changes the state" do
      mc = Markov::BidirectionalMarkovChain.new(alphabet2, order=1, lookahead=1, num_states=2)
      mc.transition(state=1, steps_left=3)
      mc.current_state.should == 1
    end
    it "updates steps_left" do
      mc = Markov::BidirectionalMarkovChain.new(alphabet2, order=1, lookahead=4, num_states=2)
      mc.transition(state=1, steps_left=2)
      mc.steps_left.should == 2
    end
  end

  context "get_expectations" do
    it "returns a random variable" do
      mc = Markov::BidirectionalMarkovChain.new(alphabet2, order=1, lookahead=1, num_states=2)
      mc.get_expectations.should be_an_instance_of Markov::RandomVariable
    end
    it "returns a random variable that is less surprised about states observed more often" do
      mc = Markov::BidirectionalMarkovChain.new(alphabet2, order=1, lookahead=1, num_states=2)
      mc.observe(state=1, steps_left=8)
      mc.observe(state=1, steps_left=8)
      mc.observe(state=0, steps_left=8)
      x = mc.get_expectations
      x.surprise_for(state=1).should be < x.surprise_for(state=0)
    end
    it "returns a random variable that only chooses states observed" do
      mc = Markov::BidirectionalMarkovChain.new(alphabet2, order=1, lookahead=1, num_states=2)
      mc.observe(state=1, steps_left=8)
      x = mc.get_expectations
      x.sample.should == 1
    end
    it "returns a random variable that only chooses states observed (higher order)" do
      mc = Markov::BidirectionalMarkovChain.new(alphabet5, order=2, lookahead=1, num_states=5)
      mc.observe(   state=1, steps_left=5)
      mc.transition(state=1, steps_left=5)
      mc.observe(   state=2, steps_left=4)
      mc.transition(state=2, steps_left=4)
      mc.observe(   state=4, steps_left=3)
      mc.transition(state=4, steps_left=3)
      mc.reset
      mc.observe(   state=0, steps_left=5)
      mc.transition(state=0, steps_left=5)
      mc.observe(   state=2, steps_left=4)
      mc.transition(state=2, steps_left=4)
      mc.observe(   state=3, steps_left=3)
      mc.transition(state=3, steps_left=3)
      mc.reset
      mc.transition(state=0, steps_left=5)
      mc.transition(state=2, steps_left=4)
      x = mc.get_expectations
      x.sample.should == 3
    end
    it "returns a random variable that only chooses states observed with the same steps remaining" do
      mc = Markov::BidirectionalMarkovChain.new(alphabet5, order=1, lookahead=1, num_states=5)
      mc.observe(   state=1, steps_left=3)
      mc.transition(state=1, steps_left=3)
      mc.observe(   state=3, steps_left=2)
      mc.transition(state=3, steps_left=2)
      mc.observe(   state=1, steps_left=1)
      mc.transition(state=1, steps_left=1)
      mc.observe(   state=2, steps_left=0)
      mc.transition(state=2, steps_left=0)
      mc.reset
      mc.transition(state=1, steps_left=1)
      x = mc.get_expectations
      x.sample.should == 2
    end
  end

end
