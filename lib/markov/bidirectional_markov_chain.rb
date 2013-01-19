module Markov
  
  class BidirectionalMarkovChain < AsymmetricBidirectionalMarkovChain
    def initialize(output_alphabet, order, lookahead)
      super(input_alphabet=output_alphabet, output_alphabet, order, lookahead)
    end
 
    def self.load(filename)
      opts = JSON.parse(File.read(filename))

      m = BidirectionalMarkovChain.new(eval(opts["output_alphabet"]), opts["order"], opts["lookahead"])
      m.set_internals(eval(opts["observations"]), eval(opts["state_history_string"]), eval(opts["steps_left"]))

      return m
    end

  end
   
end
