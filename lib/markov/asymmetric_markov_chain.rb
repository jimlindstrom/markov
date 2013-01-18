module Markov
  
  class AsymmetricMarkovChain < AsymmetricBidirectionalMarkovChain

    def initialize(alphabet, order, num_states)
      super(alphabet, order, lookahead=1, num_states)
      @fake_steps_left = lookahead+1
    end
  
    def self.load(filename)
      docs = []
      File.open(filename, 'r') do |f|
        YAML.load_stream(f).each { |d| docs.push d }
      end
      raise RuntimeError.new("bad markov file") if docs.length != 7

      m = AsymmetricMarkovChain.new(docs[0], docs[1], docs[3])
      m.set_internals(docs[4], docs[5], docs[6])

      return m
    end
 
    def observe(symbol)
      super(symbol, @fake_steps_left)
    end
  
    def transition(next_state)
      super(next_state, @fake_steps_left)
    end
  
  end
  
end
