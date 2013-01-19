shared_examples_for "a bidirectional markov chain" do
  let(:alphabet1) { Markov::LiteralAlphabet.new((1..1).to_a) }
  let(:alphabet2) { Markov::LiteralAlphabet.new((1..2).to_a) }
  let(:alphabet3) { Markov::LiteralAlphabet.new((1..3).to_a) }

  describe ".new" do
    let(:lookahead) { 2 }
    let(:order)     { 2 }
    subject { described_class.new(*params_for_new(alphabet3, order, lookahead)) }
    its(:order)     { should == order }
    its(:lookahead) { should == lookahead }
  end

  describe ".current_state" do
    subject { described_class.new(*params_for_new(alphabet2, order=2, lookahead=1)) }
    context "when in the initial state" do
      its(:current_state) { should be_nil }
    end
    context "after transition!ing" do
      before { subject.transition!(state=1, steps_left=1) }
      its(:current_state) { should == 1 }
    end
  end

  describe ".steps_left" do
    subject { described_class.new(*params_for_new(alphabet2, order=2, lookahead=2)) }
    context "if unknown" do
      its(:steps_left) { should be_nil }
    end
    context "when more steps left than the lookahead" do
      let(:steps_left) { 4 }
      before { subject.transition!(state=1, steps_left) }
      its(:steps_left) { should be_nil }
    end
    context "when 0..(lookahead-1) steps left" do
      let(:steps_left) { 1 }
      before { subject.transition!(state=1, steps_left) }
      its(:steps_left) { should == steps_left }
    end
  end

  describe ".reset!" do
    subject { described_class.new(*params_for_new(alphabet2, order=2, lookahead=1)) }
    context "after one or more transition!()s" do
      before do 
        subject.transition!(symbol=1, steps_left=0)
        subject.reset!
      end
      its(:current_state) { should be_nil }
      its(:steps_left)    { should be_nil }
    end
  end

  describe ".observe!" do
    subject { described_class.new(*params_for_new(alphabet2, order=2, lookahead=4)) }
    it "adds an observation of the next symbol" do
      state = 1
      observations_before = subject.expectations.num_observations_for(state)
      subject.observe!(state, steps_left=1)
      subject.expectations.num_observations_for(state).should be > observations_before
    end
    it "does not update state" do
      subject.transition!(cur_state=1, steps_left=1)
      subject.observe!(next_state=2, steps_left=0)
      subject.current_state.should == cur_state
    end

    context "when the symbol is not in the output alphabet" do
      let(:symbol) { 4 }
      it "raises an error" do
        expect{ subject.observe!(symbol, steps_left=2) }.to raise_error(ArgumentError)
      end
    end
    context "if the number of steps left is less than zero" do
      it "raises an error" do
        expect{ subject.observe!(symbol=1, steps_left=-1) }.to raise_error(ArgumentError)
      end
    end
    context "if steps_left is !nil and the observe!d steps_left is not exactly one less" do
      it "raises an error" do
        subject.transition!(symbol=1, steps_left=3)
        expect{ subject.observe!(symbol=1, steps_left=1) }.to raise_error(ArgumentError)
      end
    end
    it "does not update steps_left" do
      subject.transition!(symbol=2, steps_left=1)
      subject.observe!(symbol=1, steps_left=0)
      subject.steps_left.should == 1
    end
  end

  describe ".transition!" do
    subject { described_class.new(*params_for_new(alphabet2, order=2, lookahead=4)) }
    context "when the input symbol is not in the alphabet" do
      let(:invalid_symbol) { 10000 }
      it "raises an error" do
        expect{ subject.transition!(invalid_symbol, steps_left=3) }.to raise_error(ArgumentError)
      end
    end
    context "when the input symbol is in the alphabet" do
      let(:input_symbol) { 1 }
      it "does not add an observation of the next symbol" do
        subject.transition!(input_symbol, steps_left=3)
        subject.reset!
        subject.expectations.sample.should be_nil
      end
      it "changes the state" do
        subject.transition!(input_symbol, steps_left=3)
        subject.current_state.should == input_symbol
      end
      it "updates steps_left" do
        subject.transition!(input_symbol, new_steps_left=2)
        subject.steps_left.should == new_steps_left
      end
    end
  end

  describe ".expectations" do
    subject { described_class.new(*params_for_new(alphabet90, order=2, lookahead=1)) }
    its(:expectations) { should be_an_instance_of Markov::RandomVariable }
    context "when observing one state twice and another once" do
      before do
        2.times { subject.observe!(state=1, steps_left=8) }
        1.times { subject.observe!(state=2, steps_left=8) }
      end
      it "returns less surprise about the former" do
        subject.expectations.surprise_for(state=1).should be < subject.expectations.surprise_for(state=2)
      end
      it "samples only from those two states" do
        [1, 2].should include(subject.expectations.sample)
      end
    end
  end

  describe ".save" do
    let(:mc) { described_class.new(*params_for_new(alphabet2, order=2, lookahead=1)) }
    let(:filename) { "/tmp/rubymidi_bidirectional_markov_chain.yml" }
    it "saves the markov chain to a file" do
      mc.save filename
      File.exists?(filename).should == true
    end
  end

end
