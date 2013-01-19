module Markov
  
  class AsymmetricBidirectionalBackoffMarkovChain < AsymmetricBidirectionalMarkovChain

    BACK_OFF_SCALING = 0.05

    def initialize(input_alphabet, output_alphabet, order, lookahead)
      super(input_alphabet, output_alphabet, order, lookahead)
      if order == 1
        raise ArgumentError.new("You can't have a backoff chain with order 1, use AsymmetricBidirectionalMarkovChain instead")
      elsif order == 2
        @sub_chain = AsymmetricBidirectionalMarkovChain.new(input_alphabet, output_alphabet, order-1, lookahead)
      elsif order > 2
        @sub_chain = AsymmetricBidirectionalBackoffMarkovChain.new(input_alphabet, output_alphabet, order-1, lookahead)
      end
      reset!
    end

    def reset!
      super
      @sub_chain.reset! if !@sub_chain.nil?
    end
  
    def save(filename)
      super
      sub_filename = filename.gsub(/\./,"_sub.")
      @sub_chain.save(sub_filename)
    end

    def self.load(filename)
      opts = JSON.parse(File.read(filename))

      m = AsymmetricBidirectionalBackoffMarkovChain.new(eval(opts["input_alphabet"]), eval(opts["output_alphabet"]), opts["order"], opts["lookahead"])
      m.set_internals(eval(opts["observations"]), eval(opts["state_history_string"]), eval(opts["steps_left"]))

      sub_filename = filename.gsub(/\./,"_sub.")
      if m.order == 2
        m.set_sub_chain AsymmetricBidirectionalMarkovChain.load(sub_filename)
      elsif m.order > 2
        m.set_sub_chain AsymmetricBidirectionalBackoffMarkovChain.load(sub_filename)
      end
      return m
    end
  
    def observe!(output_symbol, steps_left)
      super(output_symbol, steps_left)
      @sub_chain.observe!(output_symbol, steps_left)
    end
  
    def transition!(input_symbol, steps_left)
      super(input_symbol, steps_left)
      @sub_chain.transition!(input_symbol, steps_left)
    end
  
    def expectations
      # see algorithm: http://www.doc.gold.ac.uk/~mas01mtp/papers/PearceWigginsJNMR04.pdf (p. 2)

      expectations = super
      sub_expectations = @sub_chain.expectations

      (expectations.alphabet.symbols & sub_expectations.alphabet.symbols).each do |cur_output_symbol|
        if expectations.observations[cur_output_symbol] && expectations.observations[cur_output_symbol] > 0
          # noop
        elsif sub_expectations.observations[cur_output_symbol]
          expectations.observe!(cur_output_symbol, BACK_OFF_SCALING * sub_expectations.observations[cur_output_symbol])
        end
      end

      return expectations
    end

  #protected

    def set_sub_chain(s)
      @sub_chain=s
    end

  end
  
end
