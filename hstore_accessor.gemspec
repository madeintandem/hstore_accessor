# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "hstore_accessor/version"

Gem::Specification.new do |spec|
  spec.name          = "hstore_accessor"
  spec.version       = HstoreAccessor::VERSION
  spec.authors       = ["Joe Hirn", "Cory Stephenson", "JC Grubbs"]
  spec.email         = ["joe@devmynd.com", "cory@devmynd.com", "jc@devmynd.com"]
  spec.description   = %q{Adds typed hstore backed fields to an ActiveRecord model.}
  spec.summary       = %q{Adds typed hstore backed fields to an ActiveRecord model.}
  spec.homepage      = "http://github.com/devmynd/hstore_accessor"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "pg", ">= 0.14.1"
  spec.add_dependency "activesupport", ">= 3.2.0"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
