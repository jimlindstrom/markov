module Markov
  
  class MarkovChain < AsymmetricMarkovChain
    def initialize(output_alphabet, order)
      super(input_alphabet=output_alphabet, output_alphabet, order)
    end
 
    def self.load(filename)
      opts = JSON.parse(File.read(filename))

      m = MarkovChain.new(eval(opts["output_alphabet"]), opts["order"])
      m.set_internals(eval(opts["observations"]), eval(opts["state_history_string"]), eval(opts["steps_left"]))

      return m
    end

  end

end
