$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift File.expand_path("#{File.dirname(__FILE__)}/lib")

#require "bundler/gem_tasks"
require "bundler"
Bundler::GemHelper.install_tasks

#task :spec do
#  sh "rspec -c -fd -I. -Ispec spec/*spec.rb"
#end

require 'rspec'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/*_spec.rb'
end

task :default => :spec
