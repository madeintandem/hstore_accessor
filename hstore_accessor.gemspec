# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "hstore_accessor/version"

Gem::Specification.new do |spec|
  spec.name          = "hstore_accessor"
  spec.version       = HstoreAccessor::VERSION
  spec.authors       = ["Joe Hirn", "Cory Stephenson", "JC Grubbs", "Tony Coconate"]
  spec.email         = ["joe@devmynd.com", "cory@devmynd.com", "jc@devmynd.com", "me@tonycoconate.com"]
  spec.description   = %q{Adds typed hstore backed fields to an ActiveRecord model.}
  spec.summary       = %q{Adds typed hstore backed fields to an ActiveRecord model.}
  spec.homepage      = "http://github.com/devmynd/hstore_accessor"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 4.2.0"
  spec.add_dependency "activesupport", ">= 3.2.0"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.1.0"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-nav"
  spec.add_development_dependency "pry-doc"
  spec.add_development_dependency "database_cleaner"
  spec.add_development_dependency "shoulda-matchers"

  spec.post_install_message = "Please note that there are breaking changes in version 1.0.0! Refer to the changelog here...\nhttps://github.com/devmynd/hstore_accessor#changelog"
end
