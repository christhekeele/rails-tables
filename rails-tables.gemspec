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
  s.description = "A clean jQuery datatables DSL that follows the structure of Ryan Bate's jQuery datatables railscast."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.7"
  # s.add_dependency "jquery-rails"

  s.add_development_dependency "sqlite3"
end
