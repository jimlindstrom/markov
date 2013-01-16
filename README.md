# Markov

This gem implements several variations on Markov chains. Its most
elemental model is RandomVariable. This class models a random 
variable over a finite set of integers. It can be added or multiplied by
other RandomVariables, allowing one to combine expectations from several
independent models. 

Using RandomVariable as the basis, this module implements:
* MarkovChain - a basic, nth-order markov chain
* AsymmetricMarkovChain - This markov model uses two different alphabets: one for observed
  history, and a different one for predicted next symbols.
* BidirectionalMarkovChain - This is a markov model that makes pseudo-states
  out of the number of steps left before a terminal symbol. It only has a finite lookahead,
  though, such that this capability only affects predictions in the last few symbols leading
  up to a terminal.
* AsymmetricBidirectionalMarkovChain - This model combines the features of asymmetry 
  (different alphabets of symbols for history and future) and bidirectionality (having a finite
  number of steps of lookahead, to include the number of steps to terminal as a pseudo-state).

## Installation

Add this line to your application's Gemfile:

    gem 'markov'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install markov

## Usage

      # create a new chain
      mc = Markov::MarkovChain.new(order=2, num_states=5)

      # observe the sequence 1,2,4
      mc.observe(1)
      mc.transition(1)
      mc.observe(2)
      mc.transition(2)
      mc.observe(4)
      mc.transition(4)
      mc.reset # end this sequence

      # observe the sequence 0,2,3
      mc.observe(0)
      mc.transition(0)
      mc.observe(2)
      mc.transition(2)
      mc.observe(3)
      mc.transition(3)
      mc.reset # end this sequence

      # without observing (and learning), pretend we've seen 0, 2
      mc.transition(0)
      mc.transition(2)

      # ask what the chain's expectations are at this point
      x = mc.get_expectations

      # given these expectations (a random variableS), choose an outcome.
      x.choose_outcome.should equal 3 # since 3 has been observed 100% of the time that we've seen 0, 2

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
