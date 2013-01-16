require 'yaml'

markov_files = ['version',
                'random_variable',
                'asymmetric_bidirectional_markov_chain',
                'asymmetric_markov_chain',
                'markov_chain',
                'bidirectional_markov_chain',
                'asymmetric_bidirectional_backoff_markov_chain']


markov_files.each do |file|
  require File.join('markov', file)
end

