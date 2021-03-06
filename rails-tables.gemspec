$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rails-tables/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rails-tables"
  s.version     = RailsTables::VERSION
  s.authors     = ["Christopher Keele"]
  s.email       = ["dev@chriskeele.com"]
  s.homepage    = "https://github.com/christhekeele/rails-tables"
  s.summary     = "A clean jQuery datatables DSL."
  s.description = "RailsTables is a simple DSL built on top of jquery-datatables-rails to quickly compose performant jQuery datatables for your Rails app."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  
  s.add_dependency "rails", "~> 3.0"
  s.add_dependency "railties", "~> 3.0"
  s.add_runtime_dependency "activerecord", "> 3.0"
  s.add_runtime_dependency "squeel", "~> 1.0"
  s.add_runtime_dependency "jquery-datatables-rails", "~> 1.11.0" 
  s.add_runtime_dependency "will_paginate", "~> 3.0.3"
end
