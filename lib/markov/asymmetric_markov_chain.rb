module Markov
  
  class AsymmetricMarkovChain < AsymmetricBidirectionalMarkovChain

    def initialize(input_alphabet, output_alphabet, order)
      super(input_alphabet, output_alphabet, order, lookahead=1)
      @fake_steps_left = lookahead+1
    end
  
    def self.load(filename)
      opts = JSON.parse(File.read(filename))

      m = AsymmetricMarkovChain.new(eval(opts["input_alphabet"]), eval(opts["output_alphabet"]), opts["order"])
      m.set_internals(eval(opts["observations"]), eval(opts["state_history_string"]), eval(opts["steps_left"]))

      return m
    end
 
    def observe!(output_symbol)
      super(output_symbol, @fake_steps_left)
    end
  
    def transition!(input_symbol)
      super(input_symbol, @fake_steps_left)
    end
  
  end
  
end
