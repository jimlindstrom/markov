module Markov
  
  class AsymmetricBidirectionalMarkovChain
    attr_reader :order
    attr_reader :lookahead
    attr_reader :steps_left

    LOGGING = false

    def initialize(alphabet, order, lookahead, num_states)
      raise ArgumentError.new("order must be positive") if order < 1
      raise ArgumentError.new("must have two or more states") if num_states < 2
      raise ArgumentError.new("must have a lookahead of 1 or more") if lookahead < 1
  
      @alphabet = alphabet
      @order = order
      @lookahead = lookahead
      @num_states = num_states
  
      @observations = {}
  
      reset
    end
  
    def current_state
      cur_state = @state_history_string.last
      return nil if cur_state == "nil"
      return cur_state.to_i
    end
   
    def reset
      @steps_left           = nil
      @state_history_string = ["nil"]*@order
    end
  
    def save(filename)
      File.open(filename, 'w') do |f| 
        f.puts YAML::dump @alphabet #0
        f.puts YAML::dump @order #1
        f.puts YAML::dump @lookahead #2
        f.puts YAML::dump @num_states #3
        f.puts YAML::dump @observations #4
        f.puts YAML::dump @state_history_string #5
        f.puts YAML::dump @steps_left #6
      end
    end

    def self.load(filename)
      docs = []
      File.open(filename, 'r') do |f|
        YAML.load_stream(f).each { |d| docs.push d }
      end
      raise RuntimeError.new("bad markov file") if docs.length != 7

      m = AsymmetricBidirectionalMarkovChain.new(docs[0], docs[1], docs[2], docs[3])
      m.set_internals(docs[4], docs[5], docs[6])

      return m
    end
  
    def observe(symbol, steps_left)
      raise ArgumentError.new("symbol must be in 0..(num_symbols-1) range") if (symbol < 0) or (symbol >= @alphabet.num_symbols)
      raise ArgumentError.new("steps_left cannot be negative") if (steps_left < 0)
      raise ArgumentError.new("steps_left expected to be #{@steps_left-1}") if !@steps_left.nil? and (steps_left != (@steps_left-1))
  
      k = state_history_to_key
      puts "observe    k: " + k.inspect + " => #{next_state},#{steps_left}" if LOGGING
      if @observations[k].nil?
        @observations[k] = {}
      end
      if @observations[k][symbol].nil?
        @observations[k][symbol] = 0
      end
      @observations[k][symbol] += 1
    end
  
    def transition(next_state, steps_left)
      raise ArgumentError.new("state must be in 0..(num_states-1) range") if (next_state < 0) or (next_state >= @num_states)
      raise ArgumentError.new("steps_left cannot be negative") if (steps_left < 0)
      raise ArgumentError.new("steps_left expected to be #{@steps_left-1}") if !@steps_left.nil? and (steps_left != (@steps_left-1))
  
      @state_history_string.push String(next_state || "nil")
      @state_history_string.shift

      puts "transition k: " + state_history_to_key.inspect + " (before)" if LOGGING
      @steps_left = steps_left if steps_left <= @lookahead
      puts "transition k: " + state_history_to_key.inspect + " (after)" if LOGGING
    end
  
    def expectations
      x = RandomVariable.new(@alphabet)
      k = state_history_to_key
      (@observations[k] || {}).each do |symbol, num_observations|
        x.observe!(symbol, num_observations)
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
