
describe Markov::LiteralAlphabet do
  it_should_behave_like "a finite alphabet" do
    let(:alphabet)  { Markov::LiteralAlphabet.new([1,3,5]) }
    let(:alphabet2) { Markov::LiteralAlphabet.new([2,3,4]) }
  end
end
