module Markov
  
  class BidirectionalMarkovChain < AsymmetricBidirectionalMarkovChain
    def initialize(alphabet, order, lookahead, num_states)
      super(alphabet, order, lookahead, num_states)
    end
 
    def self.load(filename)
      docs = []
      File.open(filename, 'r') do |f|
        YAML.load_stream(f).each { |d| docs.push d }
      end
      raise RuntimeError.new("bad markov file") if docs.length != 7

      m = BidirectionalMarkovChain.new(docs[0], docs[1], docs[2], docs[3])
      m.set_internals(docs[4], docs[5], docs[6])

      return m
    end

  end
   
end
