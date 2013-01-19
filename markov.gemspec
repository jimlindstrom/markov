# -*- encoding: utf-8 -*-  
$:.push File.expand_path("../lib", __FILE__)  
require "markov/version"  
  
Gem::Specification.new do |s|  
  s.name        = "markov"  
  s.version     = Markov::VERSION  
  s.platform    = Gem::Platform::RUBY  
  s.authors     = ["Jim Lindstrom"]  
  s.email       = ["jim.lindstrom@gmail.com"]  
  s.homepage    = ""  
  s.summary     = %q{Ruby implementation of various Markov models}  
  s.description = %q{Ruby implementation of various Markov models}  
  
  s.rubyforge_project = "markov"  
  
  s.files         = `git ls-files`.split("\n")  
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")  
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }  
  s.require_paths = ["lib"]  

  s.add_dependency "json"
  s.add_development_dependency "rspec"
end  
