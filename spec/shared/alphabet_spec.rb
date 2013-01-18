shared_examples_for "a finite alphabet" do
  describe ".new" do
    it "instantiates correctly" do
      alphabet.should be_an_instance_of described_class
    end
  end

  describe "#num_symbols" do
    it "returns the number of symbols" do
      alphabet.num_symbols.should be_an_instance_of Fixnum 
      alphabet.num_symbols.should be > 0
    end
  end

  describe "#symbol_class" do
    it "returns the class of the symbols" do
      alphabet.symbol_class.should be_an_instance_of Class
    end
  end

  describe "#nth_symbol" do
    context "when n is in 0..(num_symbols-1)" do
      let(:n) { alphabet.num_symbols-1 }
      it "returns an object of the same type sa #symbol_class" do
        alphabet.nth_symbol(n).should be_an_instance_of alphabet.symbol_class
      end
    end
    context "when n is outside 0..(num_symbols-1)" do
      let(:n) { alphabet.num_symbols }
      it "throws an error" do
        expect{ alphabet.nth_symbol(n) }.to raise_error
      end
    end
  end

  describe "#index_of_symbol" do
    context "when symbol the nth is in the alphabet" do
      let(:n) { 0 }
      let(:symbol) { alphabet.nth_symbol(n) }
      it "returns n" do
        alphabet.index_of_symbol(symbol).should == n
      end
    end
    context "when symbol is not in the alphabet" do
      let(:symbol) { nil }
      it "raises an error" do
        expect { alphabet.index_of_symbol(symbol) }.to raise_error
      end
    end
  end

  describe "#+" do
    subject { alphabet + alphabet2 }
    it "returns a new alphabet" do
      subject.should be_an_instance_of described_class
    end
    it "contains all symbols from both alphabets" do
      subject.symbols.should == (alphabet.symbols + alphabet2.symbols)
    end
  end

end
