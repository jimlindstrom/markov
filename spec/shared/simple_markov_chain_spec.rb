shared_examples_for "a simple markov chain" do
  let(:alphabet1) { Markov::LiteralAlphabet.new((1..1).to_a) }
  let(:alphabet2) { Markov::LiteralAlphabet.new((1..2).to_a) }

  describe "#new" do
    subject { described_class.new(*params_for_new(alphabet2, order=1)) }
    it { should be_an_instance_of described_class }
    context "when order <= 0" do
      it "raises an error" do
        expect{ described_class.new(*params_for_new(alphabet2, order=0)) }.to raise_error(ArgumentError)
      end
    end
  end

  describe ".current_state" do
    subject { described_class.new(*params_for_new(alphabet2, order=1)) }
    context "when no transition!s have occurred" do
      its(:current_state) { should be_nil }
    end
    context "when a transition! has occurred" do
      before(:all) { subject.transition!(1) }
      its(:current_state) { should == 1 }
    end
  end

  describe ".order" do
    let(:order) { 1 }
    subject { described_class.new(*params_for_new(alphabet2, order)) }
    its(:order) { should == order }
  end

  describe ".reset!" do
    subject { described_class.new(*params_for_new(alphabet2, order=1)) }
    context "when transition!()s have occurred" do
      before(:all) do
        subject.transition!(1)
      end
      it "reset!s to the initial state" do
        subject.reset!
        subject.current_state.should be_nil
      end
    end
  end

  describe ".observe!" do
    subject { described_class.new(*params_for_new(alphabet2, order=1)) }
    it "adds an observation of the next symbol" do
      num_before = subject.expectations.num_observations_for(1)
      subject.observe!(1)
      subject.expectations.num_observations_for(1).should be > num_before
    end
    it "does not update state" do
      subject.transition!(1)
      subject.observe!(2)
      subject.current_state.should == 1
    end
    context "when the symbol is not in the alphabet" do
      let(:invalid_symbol) { 3 }
      it "raises an error" do
        expect{ subject.observe!(invalid_symbol) }.to raise_error(ArgumentError)
      end
    end
  end

  describe ".transition!" do
    subject { described_class.new(*params_for_new(alphabet2, order=1)) }
    it "changes the state" do
      subject.transition!(1)
      subject.current_state.should == 1
    end
    it "does not add an observation of the next symbol" do
      subject.transition!(1)
      subject.reset!
      subject.expectations.sample.should be_nil
    end
  end

  describe ".save" do
    subject { described_class.new(*params_for_new(alphabet2, order=1)) }
    let(:filename) { "/tmp/rubymidi_markov_chain.yml" }
    it "saves the markov chain to a file" do
      subject.save filename
      File.exists?(filename).should == true
    end
  end
end
