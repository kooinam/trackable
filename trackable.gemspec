$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "trackable/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "trackable"
  s.version     = Trackable::VERSION
  s.authors     = ["kooinam"]
  s.email       = ["ngkooinam@gmail.com"]
  s.homepage    = ""
  s.summary     = "Summary of Trackable."
  s.description = "Description of Trackable."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", '~> 5.2.0'
  s.add_dependency 'haml'

  s.add_development_dependency "sqlite3"
end
