$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rel_gram/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rel_gram"
  s.version     = RelGram::VERSION
  s.authors     = ["Oleg Kotenko"]
  s.email       = ["oko10ko@ukr.net"]
  s.homepage    = ""
  s.summary     = "Summary of RelGram."
  s.description = "Description of RelGram."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.executables = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files = Dir["test/**/*"]
  s.require_paths = ['lib']
  s.rubygems_version = %q{1.9.1}

  s.add_dependency "rails"
  s.add_development_dependency "bundler"

  # s.add_development_dependency "sqlite3"
end
