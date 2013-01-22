module Markov
  
  class AsymmetricBidirectionalMarkovChain
    attr_reader :order
    attr_reader :lookahead
    attr_reader :steps_left

    LOGGING = false

    def initialize(input_alphabet, output_alphabet, order, lookahead)
      raise ArgumentError.new("order must be positive") if order < 1
      raise ArgumentError.new("must have a lookahead of 1 or more") if lookahead < 1
  
      @input_alphabet = input_alphabet
      @output_alphabet = output_alphabet
      @order = order
      @lookahead = lookahead
  
      @observations = {}
  
      reset!
    end
  
    def current_state
      cur_state = @state_history_string.last
      return nil if cur_state == "nil"
      return cur_state.to_i
    end
   
    def reset!
      @steps_left           = nil
      @state_history_string = ["nil"]*@order
    end
  
    def save(filename)
      File.open(filename, 'w') do |f| 
        f.puts({ "input_alphabet"  => "Markov::LiteralAlphabet.new(#{@input_alphabet.symbols.to_s})", # FIXME
                 "output_alphabet" => "Markov::LiteralAlphabet.new(#{@output_alphabet.symbols.to_s})", # FIXME
                 "order" => @order,
                 "lookahead" => @lookahead,
                 "observations" => @observations.to_s,
                 "state_history_string" => @state_history_string.to_s,
                 "steps_left" => @steps_left.to_s }.to_json)
      end
    end

    def self.load(filename)
      opts = JSON.parse(File.read(filename))

      m = AsymmetricBidirectionalMarkovChain.new(eval(opts["input_alphabet"]), eval(opts["output_alphabet"]), opts["order"], opts["lookahead"])
      m.set_internals(eval(opts["observations"]), eval(opts["state_history_string"]), eval(opts["steps_left"]))

      return m
    end
  
    def observe!(output_symbol, steps_left)
      unless $MARKOV__SKIP_SLOW_ERROR_CHECKING
        raise ArgumentError.new("symbol #{output_symbol} must be in alphabet #{@output_alphabet.symbols}") if !@output_alphabet.symbol_is_valid?(output_symbol)
        raise ArgumentError.new("steps_left cannot be negative") if (steps_left < 0)
        raise ArgumentError.new("steps_left expected to be #{@steps_left-1}") if !@steps_left.nil? and (steps_left != (@steps_left-1))
      end
  
      k = state_history_to_key
      if @observations[k].nil?
        @observations[k] = {}
      end
      if @observations[k][output_symbol].nil?
        @observations[k][output_symbol] = 0
      end
      @observations[k][output_symbol] += 1
    end
  
    def transition!(input_symbol, steps_left)
      unless $MARKOV__SKIP_SLOW_ERROR_CHECKING
        raise ArgumentError.new("symbol #{input_symbol} must be in alphabet #{@input_alphabet.symbols}") if !@input_alphabet.symbol_is_valid?(input_symbol)
        raise ArgumentError.new("steps_left cannot be negative") if (steps_left < 0)
        raise ArgumentError.new("steps_left expected to be #{@steps_left-1}") if !@steps_left.nil? and (steps_left != (@steps_left-1))
      end
  
      @state_history_string.push String(input_symbol || "nil")
      @state_history_string.shift

      @steps_left = steps_left if steps_left <= @lookahead
    end
  
    def expectations
      x = RandomVariable.new(@output_alphabet)
      k = state_history_to_key
      (@observations[k] || {}).each do |output_symbol, num_observations|
        x.observe!(output_symbol, num_observations)
      end
      return x
    end

  # FIXME: This is terrible.  How else can (only) self.load set these though?
    def set_internals(o, shs, sl)
      @observations         = o
      @state_history_string = shs
      @steps_left           = sl
    end

  private
    def state_history_to_key
      @state_history_string.join(',') + ',' + String(@steps_left || "nil")
    end
  
  end
  
end
