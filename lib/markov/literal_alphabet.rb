module Markov
  class LiteralAlphabet
    def initialize(alphabet)
      @alphabet = alphabet

      classes = @alphabet.map{ |symbol| symbol.class }.uniq
      raise RuntimeError.new("all symbols must be of the same class") if classes.length > 1
      @symbol_class = classes.first
    end

    def symbols
      @alphabet
    end

    def num_symbols
      @alphabet.length
    end

    def symbol_class
      @symbol_class
    end

    def nth_symbol(n)
      raise RuntimeError.new("n must be in 0..(num_symbols-1)") if n<0 || n>=num_symbols
      @alphabet[n]
    end

    def index_of_symbol(sym)
      if !(idx = @alphabet.find_index(sym))
        raise RuntimeError.new("symbol not found") 
      end
      idx
    end

    def symbol_is_valid?(sym)
      @alphabet.include?(sym)
    end

    def +(other)
      LiteralAlphabet.new((symbols + other.symbols).uniq)
    end
  end
end
