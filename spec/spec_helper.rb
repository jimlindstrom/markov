require "bundler"

envs = [:default, :development]
envs << :debug if ENV["DEBUG"]
Bundler.setup(*envs)

$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), "../lib")))
require "markov"

Dir["./spec/shared/**/*.rb"].sort.each {|f| require f}

require 'rspec'

