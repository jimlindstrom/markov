#!/usr/bin/env ruby 

describe Markov::RandomVariable do
  describe ".new" do
    it "creates a blank random variable with a fixed number of outcomes" do
      Markov::RandomVariable.new(num_outcomes=5).should be_an_instance_of Markov::RandomVariable
    end
    context "if the number of outcomes is less than 1" do
      let(:num_outcomes) { 0 }
      it "raises an error if the number of outcomes is less than 1" do
        expect{ Markov::RandomVariable.new(num_outcomes) }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#transform_outcomes!" do
    let(:num_outcomes) { 5 }
    let(:x) { Markov::RandomVariable.new(num_outcomes) }
    it "runs a transform on each outcome" do
      x.observe!(outcome=3, num_observations=10)

      x.transform_outcomes!(lambda { |y| y*10 }, lambda { |y| y/10 })

      x.choose_outcome.should == 30
    end
    it "causes 'surprise_for' to reverse-transform the given outcome" do
      x.observe!(outcome=1)
      x.transform_outcomes!(lambda { |y| y*10 }, lambda { |y| y/10 })
      x.surprise_for(10).should be_within(0.01).of(0.0)
    end
  end

  describe "#+" do
    before (:each) do
      @x1 = Markov::RandomVariable.new(@num_outcomes=5)
      @x1.observe!(@outcome=3, @num_observations=10)

      @x2 = Markov::RandomVariable.new(@num_outcomes=5)
      @x2.observe!(@outcome=4, @num_observations=1)

      @sum = @x1 + @x2
    end
    it "combines the random variables, so that surprise_for still works" do
      @sum.surprise_for(3).should be < @sum.surprise_for(4)
    end
    it "combines the random variables, so that surprise_for still works" do
      @sum.surprise_for(4).should be < 1.0
    end
    it "combines the random variables, such that choose_outcome uses outcomes from both random variables" do
      [3, 4].should include(@sum.choose_outcome)
    end
    context "when the first one is transformed" do
      it "combines the random variables" do
        @x1.transform_outcomes!(lambda {|y| y+1}, lambda {|y| y-1})
        (@x1 + @x2).choose_outcome.should == 4
      end
    end
    context "when the second one is transformed" do
      it "combines the random variables" do
        @x2.transform_outcomes!(lambda {|y| y-1}, lambda {|y| y+1})
        (@x1 + @x2).choose_outcome.should == 3
      end
    end
    context "when the two have different numbers of outcomes and are transformed" do
      before(:all) do
        @x1 = Markov::RandomVariable.new(num_outcomes=5)
        @x1.observe!(outcome=4, num_observations=10)
        @x1.transform_outcomes!(lambda {|y| y+21}, lambda {|y| y-21})
  
        @x2 = Markov::RandomVariable.new(num_outcomes=2)
        @x2.observe!(outcome=0)
        @x2.transform_outcomes!(lambda {|y| y-1}, lambda {|y| y+1})
      end
      it "combines the random variables, even the two have different numbers of outcomes and are transformed" do
        [3].should include((@x1 + @x2).choose_outcome)
      end
    end
  end

  describe "#*" do
    before(:each) do
      @x1 = Markov::RandomVariable.new(@num_outcomes=6)
      @x1.observe!(@outcome=2, @num_observations=5)
      @x1.observe!(@outcome=3, @num_observations=10)
      @x1.observe!(@outcome=4, @num_observations=5)

      @x2 = Markov::RandomVariable.new(@num_outcomes=6)
      @x2.observe!(@outcome=3, @num_observations=4)
      @x2.observe!(@outcome=4, @num_observations=12)
      @x2.observe!(@outcome=5, @num_observations=4)
      @product = @x1 * @x2
    end
    it "combines the random variables, so that surprise_for still works" do
      @product.surprise_for(3).should be < @product.surprise_for(2)
    end
    it "combines the random variables, so that surprise_for still works" do
      @product.surprise_for(4).should be < 1.0
    end
    it "combines the random variables, such that choose_outcome uses outcomes from both random variables" do
      [3, 4].include?(@product.choose_outcome).should be_true
    end
    context "when the first one is trasnformed" do
      before { @x1.transform_outcomes!(lambda {|y| y-1}, lambda {|y| y+1}) }
      it "combines the random variables" do
        (@x1 * @x2).choose_outcome.should == 3
      end
    end
    context "when the second one is trasnformed" do
      before { @x2.transform_outcomes!(lambda {|y| y+1}, lambda {|y| y-1}) }
      it "combines the random variables" do
        (@x1 * @x2).choose_outcome.should == 4
      end
    end
    context "when the two have different numbers of outcomes and are transformed" do
      before(:all) do
        @x1 = Markov::RandomVariable.new(num_outcomes=50)
        @x1.observe!(outcome=4, num_observations=10)
        @x1.transform_outcomes!(lambda {|y| y+21}, lambda {|y| y-21})
  
        @x2 = Markov::RandomVariable.new(num_outcomes=50)
        @x2.observe!(outcome=26)
        @x2.transform_outcomes!(lambda {|y| y-1},  lambda {|y| y+1})
      end
      it "combines the random variables" do
        [3, 4].should include( (@x1 * @x2).choose_outcome ) # FIXME: is this right?  How does this math work out?
      end
    end
  end

  describe "#observe!" do
    let(:num_outcomes) { 3 }
    subject { Markov::RandomVariable.new(num_outcomes) }
    context "when the the observed outcome is outside 0..(num_outcomes-1)" do
      let(:outcome) { -1 }
      let(:num_observations) { 5 }
      it "raises an error" do
        expect{ subject.observe!(outcome, num_observations) }.to raise_error(ArgumentError)
      end
    end
    context "when num_observations is negative" do
      let(:outcome) { 1 }
      let(:num_observations) { -5 }
      it "raises an error" do
        expect{ subject.observe!(outcome, num_observations) }.to raise_error(ArgumentError)
      end
    end
    context "when '2' has been observed 5 times" do
      before { subject.observe!(outcome=2, num_observations=5) }
      it "increases the probability that the possible outcome will be chosen" do
        subject.choose_outcome.should == 2
      end
      it "increases the number of observations" do
        subject.num_observations.should == 5
      end
    end
  end

  describe "#num_observations" do
    let(:num_outcomes) { 3 }
    subject { Markov::RandomVariable.new(num_outcomes) }
    context "when no observations have been made" do
      its(:num_observations) { should == 0 }
    end
    context "when 5 observations have been made" do
      before(:all) do
        subject.observe!(outcome=2)
        subject.observe!(outcome=2, num_observations=2)
        subject.observe!(outcome=2, num_observations=3)
      end
      its(:num_observations) { should == (1+2+3) }
    end
  end

  describe "#choose_outcome" do
    it "returns nil if no possibilities have been added" do
      x = Markov::RandomVariable.new(num_outcomes=5)
      x.choose_outcome.should be_nil
    end
    it "returns one of the possible outcomes" do
      x = Markov::RandomVariable.new(num_outcomes=5)
      x.observe!(outcome=1)
      x.observe!(outcome=2, num_observations=2)
      [1, 2].include?(x.choose_outcome).should be true
    end
  end

  describe "#probability" do
    it "returns the probability of an outcome" do
      x = Markov::RandomVariable.new(num_outcomes=5)
      x.observe!(outcome=1)
      x.observe!(outcome=2, num_observations=2)
      x.probability(1).should be_within(0.01).of(1.0/3.0)
    end
    it "raises an error if nothing has been observed" do
      x = Markov::RandomVariable.new(num_outcomes=5)
      expect { x.probability(0) }.to raise_error
    end
  end

  describe "#scale!" do # FIXME: no one seems to be using this. Get rid of it?
    let(:num_outcomes) { 5 }
    subject { Markov::RandomVariable.new(num_outcomes) }
    it "increases the number of observations of all outcomes by a scaling factor" do
      subject.observe!(outcome=1)
      subject.scale!(2.0)
      subject.observe!(outcome=2, num_observations=2)
      subject.probability(1).should be_within(0.0001).of(subject.probability(2))
    end
  end

  describe "#surprise_for" do
    let(:num_outcomes) { 5 }
    subject { Markov::RandomVariable.new(num_outcomes) }
    context "if no observations have been made" do
      it "returns 0.5" do
        subject.surprise_for(0).should be_within(0.01).of(0.5)
      end
    end

    context "if one observation has been made" do
      before(:all) do
        subject.observe!(outcome=1)
      end
      it "returns 0.0 for an outcome that is the only one observed" do
        subject.surprise_for(1).should be_within(0.01).of(0.0)
      end
    end

    context "if multiple observations have been made" do
      before(:all) do
        subject.observe!(outcome=1)
        subject.observe!(outcome=2, num_observations=2)
      end
      it "returns a value between 0.0 and 1.0" do
        subject.surprise_for(0).should be_between(0.0, 1.0)
      end
      it "returns 1.0 for outcomes that have never been observed" do
        subject.surprise_for(0).should be_within(0.01).of(1.0)
      end
      it "returns higher values (more surprise) for outcomes that have been observed less" do
        subject.surprise_for(1).should be > subject.surprise_for(2)
      end
    end
  end

  describe "#entropy" do
    let(:num_outcomes) { 5 }
    subject {  Markov::RandomVariable.new(num_outcomes=5) }
    context "if no outcomes have occurred" do
      it "raises an error if no outcomes have been observed" do
        expect{ subject.entropy }.to raise_error(RuntimeError)
      end
    end
    context "if some outcomes have occurred" do
      before(:all) do
        subject.observe!(outcome=0)
        subject.observe!(outcome=1, num_observations=3)
      end
      it "returns a value, H, that represents the uncertainty of the random variable" do
        expected_H = 0.0 - (0.25 * Math.log2(0.25)) - (0.75 * Math.log2(0.75))
        subject.entropy.should be_within(0.01).of(expected_H)
      end
    end
  end

  describe "#max_entropy" do
    let(:num_outcomes) { 5 }
    subject { Markov::RandomVariable.new(num_outcomes) }
    its(:max_entropy) { should be_within(0.01).of(Math.log2(num_outcomes)) }
  end

  describe "#information_content" do
    let(:num_outcomes) { 5 }
    let(:x) { Markov::RandomVariable.new(num_outcomes) }
    before(:each) do
      x.observe!(outcome=0)
      x.observe!(outcome=1, num_observations=3)
      @prob_of_outcome = 3.0 / 4.0
    end
    it "returns the information content (unexpectedness) associated with a particular outcome" do
      expected_ic = Math.log2(1.0 / @prob_of_outcome)
      x.information_content(outcome=1).should be_within(0.01).of(expected_ic)
    end
    context "for zero-probability events" do
      it "returns max_information_content" do
        expected_ic = Markov::RandomVariable.max_information_content
        x.information_content(outcome=2).should be_within(0.01).of(expected_ic)
      end
    end
  end

end
