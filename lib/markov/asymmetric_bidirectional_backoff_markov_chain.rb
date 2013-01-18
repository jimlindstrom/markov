module Markov
  
  class AsymmetricBidirectionalBackoffMarkovChain < AsymmetricBidirectionalMarkovChain

    BACK_OFF_SCALING = 0.05

    def initialize(alphabet, order, lookahead, num_states)
      super(alphabet, order, lookahead, num_states)
      if order == 1
        raise ArgumentError.new("You can't have a backoff chain with order 1, use AsymmetricBidirectionalMarkovChain instead")
      elsif order == 2
        @sub_chain = AsymmetricBidirectionalMarkovChain.new(alphabet, order-1, lookahead, num_states)
      elsif order > 2
        @sub_chain = AsymmetricBidirectionalBackoffMarkovChain.new(alphabet, order-1, lookahead, num_states)
      end
      reset
    end

    def reset
      super
      @sub_chain.reset if !@sub_chain.nil?
    end
  
    def save(filename)
      super
      sub_filename = filename.gsub(/\./,"_sub.")
      @sub_chain.save(sub_filename)
    end

    def self.load(filename)
      docs = []
      File.open(filename, 'r') do |f|
        YAML.load_stream(f).each { |d| docs.push d }
      end
      raise RuntimeError.new("bad markov file") if docs.length != 7

      m = AsymmetricBidirectionalBackoffMarkovChain.new(docs[0], docs[1], docs[2], docs[3])
      m.set_internals(docs[4], docs[5], docs[6])

      sub_filename = filename.gsub(/\./,"_sub.")
      if m.order == 2
        m.set_sub_chain AsymmetricBidirectionalMarkovChain.load(sub_filename)
      elsif m.order > 2
        m.set_sub_chain AsymmetricBidirectionalBackoffMarkovChain.load(sub_filename)
      end
      return m
    end
  
    def observe(symbol, steps_left)
      super(symbol, steps_left)
      @sub_chain.observe(symbol, steps_left)
    end
  
    def transition(next_state, steps_left)
      super(next_state, steps_left)
      @sub_chain.transition(next_state, steps_left)
    end
  
    def expectations
      # see algorithm: http://www.doc.gold.ac.uk/~mas01mtp/papers/PearceWigginsJNMR04.pdf (p. 2)

      expectations = super
      sub_expectations = @sub_chain.expectations

      0.upto([    expectations.alphabet.num_symbols-1, 
              sub_expectations.alphabet.num_symbols-1].max) do |cur_symbol|
        if expectations.observations[cur_symbol] && expectations.observations[cur_symbol] > 0
          # noop
        elsif expectations.observations[cur_symbol] == 0
          expectations.observe!(cur_symbol, BACK_OFF_SCALING * sub_expectations.observations[cur_symbol])
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
