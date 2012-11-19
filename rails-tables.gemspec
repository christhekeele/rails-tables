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
  s.description = "A clean jQuery datatables DSL."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  
  s.add_dependency "rails", "~> 3.2.7"
  s.add_dependency "railties", "~> 3.1"
  s.add_runtime_dependency "jquery-datatables-rails", "~> 1.11.0" 
  s.add_runtime_dependency "will_paginate", "~> 3.0.3"
  s.add_runtime_dependency "squeel", "~> 1.0.11"
end
