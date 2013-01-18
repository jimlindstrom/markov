module Markov
  
  class RandomVariable
    attr_reader :num_observations
    attr_reader :observations
    attr_reader :alphabet

    def initialize(alphabet)
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

    def num_observations_for(symbol)
      @observations[symbol] || 0
    end
    
    def observe!(symbol, num_observations=1)
      raise ArgumentError.new("num_observations must be >= 0") if num_observations < 0
      raise ArgumentError.new("symbol must be >= 0") if symbol < 0
      raise ArgumentError.new("symbol must be < #{@alphabet.num_symbols}") if symbol >= @alphabet.num_symbols
  
      @observations[symbol] = (@observations[symbol] || 0) + num_observations
      @num_observations += num_observations
    end
  
    def sample
      # we can't generate anything w/o any observations
      return nil if @num_observations == 0
  
      # generate a outcome, based on the CDF
      observed_symbols = @observations.keys
      r = (rand*(observed_symbols.length-1.0)).round
  
      symbol = observed_symbols.shift
      while r >= @observations[symbol]
        r -= @observations[symbol]
        symbol = observed_symbols.shift
      end
      return symbol
  
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

