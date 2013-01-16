#require 'thread' # FIXME: I'm not sure this is used, actually.
require 'yaml'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))

require File.join(File.dirname(__FILE__), 'markov', 'version')
require File.join(File.dirname(__FILE__), 'markov', 'random_variable')
require File.join(File.dirname(__FILE__), 'markov', 'asymmetric_bidirectional_markov_chain')
require File.join(File.dirname(__FILE__), 'markov', 'asymmetric_markov_chain')
require File.join(File.dirname(__FILE__), 'markov', 'markov_chain')
require File.join(File.dirname(__FILE__), 'markov', 'bidirectional_markov_chain')
require File.join(File.dirname(__FILE__), 'markov', 'asymmetric_bidirectional_backoff_markov_chain')
