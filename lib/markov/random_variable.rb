module Markov
  
  class RandomVariable
    attr_reader :num_observations
    attr_reader :observations
    attr_reader :alphabet

    def initialize(alphabet)
      raise RuntimeError.new("Alphabet cannot be nil") if !alphabet

      @alphabet              = alphabet
      @num_observations      = 0
      @observations          = { }
    end
  
    def +(other)
      rnew = RandomVariable.new(@alphabet + other.alphabet)
      
      @observations.each      { |symbol, num_obs| rnew.observe!(symbol, num_obs) }
      other.observations.each { |symbol, num_obs| rnew.observe!(symbol, num_obs) }
  
      return rnew
    end
 
    def *(other)
      rnew = RandomVariable.new(@alphabet + other.alphabet)
      
      prod_syms  = @observations.keys & other.observations.keys
      prod_syms.each do |symbol|
        rnew.observe!(symbol, @observations[symbol] * other.observations[symbol])
      end
  
      return rnew
    end

    def normalized_and_weighted_by_entropy
      rnew = RandomVariable.new(@alphabet)
      
      scale = (1.0 / (@num_observations + 0.1)) * (max_entropy / (entropy + 0.1))
      @observations.each { |symbol, num_obs| rnew.observe!(symbol, num_obs*scale) }
  
      return rnew
    end

    def num_observations_for(symbol)
      @observations[symbol] || 0
    end
    
    def observe!(symbol, num_observations=1)
      unless $MARKOV__SKIP_SLOW_ERROR_CHECKING
        raise ArgumentError.new("num_observations must be >= 0") if num_observations < 0
        raise ArgumentError.new("symbol must be valid") if !@alphabet.symbol_is_valid?(symbol)
      end
  
      @observations[symbol] = (@observations[symbol] || 0) + num_observations
      @num_observations += num_observations
    end
  
    def sample
      # we can't generate anything w/o any observations
      return nil if @num_observations == 0
  
      # generate a outcome, based on the CDF
      observed_symbols = @observations.keys
      r = rand*@observations.values.inject(:+)
  
      symbol = observed_symbols.shift
      # the first two clauses on this while loop are to avoid the rare case of floating point
      # rounding error accumulation. Ideally r would never exceed the sum of the observed observations,
      # but we're repeatedly subtracting a floating point value from r, such that sometimes, this
      # while loop would otherwise enter a final phantom iteration, and try to pick a nil symbol.
      while (symbol) && (@observations[symbol]) && (r >= @observations[symbol])
        r -= @observations[symbol]
        symbol = observed_symbols.shift
      end
      return symbol if symbol # the usual case
      return @observations.keys.last # in case floating point error pushes us past the end.
    end
    
    def probability_of(symbol)
      raise RuntimeError.new("probability is undefined without observations") if @num_observations == 0
      return @observations[symbol].to_f / @num_observations
    end
  
    def surprise_for(symbol)
      return 0.5 if @num_observations == 0
  
      cur_expectation = @observations[symbol] || 0
      max_expectation = @observations.values.max
      surprise = (max_expectation - cur_expectation).to_f / max_expectation
  
      return surprise
    end

    # This is a more information theoretic version of 'surprise_for' that 
    # returns the amount of informational content associated with a particular
    # outcome, given the context of this state.
    def information_content_for(symbol)
      raise RuntimeError.new("information content doesn't make sense without observations") if @num_observations == 0
      p = probability_of(symbol)
      return RandomVariable::max_information_content if p < 1.0e-10
      return Math.log2(1.0 / p)
    end

    def self.max_information_content 
      Math.log2(1.0 / (1.0 / 1000000)) # this is arbitrary...
    end

    # The maximum entropy that COULD be observed is a function of the number of 
    # outcomes.  The units of this value is "bits"
    def max_entropy
      Math.log2(@alphabet.num_symbols)
    end

    # This has two interpretations: (1) A lower bound on the average number of 
    # bits needed to encode the outcome of this random variable.  (2) The amount 
    # of uncertainty in this context.
    def entropy
      raise RuntimeError.new("entropy is undefined until there are observations") if @num_observations == 0
  
      cur_H = 0.0
      @observations.values.each do |cur_observations|
        if cur_observations > 0
          cur_probability = cur_observations.to_f / @num_observations
          cur_H -= cur_probability * Math.log2(cur_probability)
        end
      end
  
      return cur_H
    end
  
  end

end

