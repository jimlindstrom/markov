#!/usr/bin/env ruby 

describe Markov::RandomVariable do
  let(:small_alphabet) { Markov::LiteralAlphabet.new((0..10).to_a) }
  let(:big_alphabet)   { Markov::LiteralAlphabet.new((5..100).to_a) }
  let(:combo_alphabet) { Markov::LiteralAlphabet.new((0..100).to_a) }

  describe ".new" do
    it "creates a random variable" do
      Markov::RandomVariable.new(small_alphabet).should be_an_instance_of described_class
    end
  end

  describe "#+" do
    before(:all) do
      @x1 = Markov::RandomVariable.new(small_alphabet)
      @x1.observe!(symbol=3, num_observations=10)

      @x2 = Markov::RandomVariable.new(big_alphabet)
      @x2.observe!(symbol=9, num_observations=1)

      @sum = @x1 + @x2
    end
    it "adds the observations of each RV" do
      @sum.num_observations_for(3).should == 10
      @sum.num_observations_for(9).should ==  1
    end
    it "produces symbols from both RVs" do
      ([3]+[9]).should include(@sum.sample)
    end
    it "uses the superset alphabet" do
      @sum.alphabet.num_symbols == combo_alphabet.num_symbols
    end
  end

  describe "#*" do
    before(:all) do
      @x1 = Markov::RandomVariable.new(small_alphabet)
      @x1.observe!(symbol=3, num_observations=1)
      @x1.observe!(symbol=5, num_observations=5)
      @x1.observe!(symbol=7, num_observations=2)

      @x2 = Markov::RandomVariable.new(big_alphabet)
      @x2.observe!(symbol= 5, num_observations=2)
      @x2.observe!(symbol= 7, num_observations=3)
      @x2.observe!(symbol=11, num_observations=4)

      @product = @x1 * @x2
    end
    it "multiplies the observations of each RV" do
      @product.num_observations_for(5).should == 5*2
      @product.num_observations_for(7).should == 2*3
    end
    it "produces symbols from the intersection of both RVs" do
      ([3,5,7]&[5,7,11]).should include(@product.sample)
    end
    it "uses the superset alphabet" do
      @product.alphabet.num_symbols == combo_alphabet.num_symbols
    end
  end

  describe "#normalized_and_weighted_by_entropy" do
    it "returns a new random variable" do
      pending
    end
    it "its alphabet is the same" do
      pending
    end
    it "its observations are proportional, but scaled by 1/observations*max_entropy/entropy" do
      # this isn't strictly true, because I had to add a fudge factor. Why is that?
      pending
    end
  end

  describe "#observe!" do
    subject { Markov::RandomVariable.new(small_alphabet) }
    context "when the the observed symbol is outside 0..(num_symbols-1)" do
      let(:symbol) { -1 }
      let(:num_observations) { 5 }
      it "raises an error" do
        expect{ subject.observe!(symbol, num_observations) }.to raise_error(ArgumentError)
      end
    end
    context "when num_observations is negative" do
      let(:symbol) { 1 }
      let(:num_observations) { -5 }
      it "raises an error" do
        expect{ subject.observe!(symbol, num_observations) }.to raise_error(ArgumentError)
      end
    end
    context "when '2' has been observed 5 times" do
      before { subject.observe!(symbol=2, num_observations=5) }
      it "increases the probability that the possible symbol will be chosen" do
        subject.sample.should == 2
      end
      it "increases the number of observations" do
        subject.num_observations.should == 5
      end
    end
  end

  describe "#num_observations" do
    subject { Markov::RandomVariable.new(small_alphabet) }
    context "when no observations have been made" do
      its(:num_observations) { should == 0 }
    end
    context "when 5 observations have been made" do
      before(:all) do
        subject.observe!(symbol=2)
        subject.observe!(symbol=2, num_observations=2)
        subject.observe!(symbol=2, num_observations=3)
      end
      its(:num_observations) { should == (1+2+3) }
    end
  end

  describe "#num_observations_for" do
    subject { Markov::RandomVariable.new(small_alphabet) }
    context "when no observations of x have been made" do
      it "returns 0" do
        subject.num_observations_for(2).should == 0
      end
    end
    context "when 3 observations of x have been made" do
      before(:all) do
        subject.observe!(symbol=1)
        subject.observe!(symbol=2, num_observations=2)
        subject.observe!(symbol=3, num_observations=3)
      end
      it "returns 3" do
        subject.num_observations_for(2).should == 2
      end
    end
  end

  describe "#sample" do
    let(:x) { Markov::RandomVariable.new(small_alphabet) }
    context "if no observations" do
      it "returns nil if no possibilities have been added" do
        x.sample.should be_nil
      end
    end
    context "if some observations" do
      before(:each) do
        x.observe!(symbol=1)
        x.observe!(symbol=2, num_observations=2)
      end
      it "returns an observed symbol" do
        [1, 2].should include(x.sample)
      end
    end
  end

  describe "#probability_of" do
    let(:x) { Markov::RandomVariable.new(small_alphabet) }
    before(:all) do
      x.observe!(symbol=1)
      x.observe!(symbol=2, num_observations=2)
    end
    context "given an observed symbol" do
      it "returns the observed probability" do
        x.probability_of(1).should be_within(0.01).of(1.0/3.0)
      end
    end
    context "given an unobserved symbol" do
      it "returns 0.0" do
        x.probability_of(3).should be_within(0.01).of(0.0)
      end
    end
  end

  describe "#surprise_for" do
    subject { Markov::RandomVariable.new(small_alphabet) }
    context "if no observations have been made" do
      it "returns 0.5" do
        subject.surprise_for(0).should be_within(0.01).of(0.5)
      end
    end
    context "if one observation has been made" do
      before(:all) do
        subject.observe!(symbol=1)
      end
      it "returns 0.0 for an symbol that is the only one observed" do
        subject.surprise_for(1).should be_within(0.01).of(0.0)
      end
    end
    context "if multiple observations have been made" do
      before(:all) do
        subject.observe!(symbol=1)
        subject.observe!(symbol=2, num_observations=2)
      end
      it "returns a value between 0.0 and 1.0" do
        subject.surprise_for(0).should be_between(0.0, 1.0)
      end
      it "returns 1.0 for symbols that have never been observed" do
        subject.surprise_for(0).should be_within(0.01).of(1.0)
      end
      it "returns higher values (more surprise) for symbols that have been observed less" do
        subject.surprise_for(1).should be > subject.surprise_for(2)
      end
    end
  end

  describe "#entropy" do
    subject {  Markov::RandomVariable.new(small_alphabet) }
    context "if no symbols have occurred" do
      it "raises an error if no symbols have been observed" do
        expect{ subject.entropy }.to raise_error(RuntimeError)
      end
    end
    context "if some symbols have occurred" do
      before(:all) do
        subject.observe!(symbol=0)
        subject.observe!(symbol=1, num_observations=3)
      end
      it "returns the uncertainty, in bits, of the random variable" do
        expected_H = 0.0 - (0.25 * Math.log2(0.25)) - (0.75 * Math.log2(0.75))
        subject.entropy.should be_within(0.01).of(expected_H)
      end
    end
  end

  describe "#max_entropy" do
    subject {  Markov::RandomVariable.new(small_alphabet) }
    its(:max_entropy) { should be_within(0.01).of(Math.log2(small_alphabet.num_symbols)) }
  end

  describe "#information_content_for" do
    let(:x) {  Markov::RandomVariable.new(small_alphabet) }
    before(:each) do
      x.observe!(symbol=0)
      x.observe!(symbol=1, num_observations=3)
      @prob_of_symbol = 3.0 / 4.0
    end
    it "returns the information content (unexpectedness) associated with a particular symbol" do
      expected_ic = Math.log2(1.0 / @prob_of_symbol)
      x.information_content_for(symbol=1).should be_within(0.01).of(expected_ic)
    end
    context "for zero-probability events" do
      it "returns max_information_content" do
        expected_ic = Markov::RandomVariable.max_information_content
        x.information_content_for(symbol=2).should be_within(0.01).of(expected_ic)
      end
    end
  end

end
