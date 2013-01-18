shared_examples_for "a bidirectional markov chain" do
  let(:alphabet1) { Markov::LiteralAlphabet.new((1..1).to_a) }
  let(:alphabet2) { Markov::LiteralAlphabet.new((1..2).to_a) }
  let(:alphabet3) { Markov::LiteralAlphabet.new((1..3).to_a) }

  describe ".new" do
    let(:lookahead) { 2 }
    let(:order)     { 2 }
    subject { described_class.new(alphabet3, order, lookahead, num_states=3) }
    its(:order)     { should == order }
    its(:lookahead) { should == lookahead }
  end

  describe ".current_state" do
    subject { described_class.new(alphabet2, order=2, lookahead=1, num_states=2) }
    context "when in the initial state" do
      its(:current_state) { should be_nil }
    end
    context "after transitioning" do
      before { subject.transition(state=0, steps_left=1) }
      its(:current_state) { should == 0 }
    end
  end

  describe ".steps_left" do
    subject { described_class.new(alphabet2, order=2, lookahead=2, num_states=2) }
    context "if unknown" do
      its(:steps_left) { should be_nil }
    end
    context "when more steps left than the lookahead" do
      let(:steps_left) { 4 }
      before { subject.transition(state=1, steps_left) }
      its(:steps_left) { should be_nil }
    end
    context "when 0..(lookahead-1) steps left" do
      let(:steps_left) { 1 }
      before { subject.transition(state=1, steps_left) }
      its(:steps_left) { should == steps_left }
    end
  end

  describe ".reset" do
    subject { described_class.new(alphabet2, order=2, lookahead=1, num_states=2) }
    context "after one or more transition()s" do
      before do 
        subject.transition(state=0, steps_left=0)
        subject.reset
      end
      its(:current_state) { should be_nil }
      its(:steps_left)    { should be_nil }
    end
  end

  describe ".observe" do
    let(:num_states) { 2 }
    subject { described_class.new(alphabet2, order=2, lookahead=4, num_states) }
    it "adds an observation of the next symbol" do
      state = 0
      observations_before = subject.expectations.num_observations_for(state)
      subject.observe(state, steps_left=1)
      subject.expectations.num_observations_for(state).should be > observations_before
    end
    it "does not update state" do
      subject.transition(cur_state=1, steps_left=1)
      subject.observe(next_state=0, steps_left=0)
      subject.current_state.should == cur_state
    end

    context "if the state is outside the 0..(num_states-1) range" do
      it "raises an error" do
        expect{ subject.observe(state=num_states, steps_left=2) }.to raise_error(ArgumentError)
      end
    end
    context "if the number of steps left is less than zero" do
      it "raises an error" do
        expect{ subject.observe(state=1, steps_left=-1) }.to raise_error(ArgumentError)
      end
    end
    context "if steps_left is !nil and the observed steps_left is not exactly one less" do
      it "raises an error" do
        subject.transition(state=1, steps_left=3)
        expect{ subject.observe(state=1, steps_left=1) }.to raise_error(ArgumentError)
      end
    end
    it "does not update steps_left" do
      subject.transition(state=1, steps_left=1)
      subject.observe(state=0, steps_left=0)
      subject.steps_left.should == 1
    end
  end

  describe ".transition" do
    let(:num_states) { 2 }
    subject { described_class.new(alphabet2, order=2, lookahead=4, num_states) }
    context "when the state is outside the 0..(num_states-1) range" do
      it "raises an error" do
        expect{ subject.transition(state=num_states, steps_left=3) }.to raise_error(ArgumentError)
      end
    end
    it "does not add an observation of the next symbol" do
      subject.transition(state=1, steps_left=3)
      subject.reset
      subject.expectations.sample.should be_nil
    end
    it "changes the state" do
      subject.transition(next_state=1, steps_left=3)
      subject.current_state.should == next_state
    end
    it "updates steps_left" do
      subject.transition(state=1, new_steps_left=2)
      subject.steps_left.should == new_steps_left
    end
  end

  describe ".expectations" do
    subject { described_class.new(alphabet2, order=2, lookahead=1, num_states=2) }
    its(:expectations) { should be_an_instance_of Markov::RandomVariable }
    context "when observing one state twice and another once" do
      before do
        2.times { subject.observe(state=1, steps_left=8) }
        1.times { subject.observe(state=0, steps_left=8) }
      end
      it "returns less surprise about the former" do
        subject.expectations.surprise_for(state=1).should be < subject.expectations.surprise_for(state=0)
      end
      it "samples only from those two states" do
        [0, 1].should include(subject.expectations.sample)
      end
    end
  end

  describe ".save" do
    let(:mc) { described_class.new(alphabet2, order=2, lookahead=1, num_states=2) }
    let(:filename) { "/tmp/rubymidi_bidirectional_markov_chain.yml" }
    it "saves the markov chain to a file" do
      mc.save filename
      File.exists?(filename).should == true
    end
  end

end
