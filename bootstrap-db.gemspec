# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bootstrap/db/version'

Gem::Specification.new do |spec|
  spec.name          = "bootstrap-db"
  spec.version       = Bootstrap::Db::VERSION
  spec.authors       = ["Tom Meier"]
  spec.email         = ["tom@venombytes.com"]
  spec.description   = %q{Database dump and loader}
  spec.summary       = %q{Database dump and loader}
  spec.homepage      = "http://github.com/tommeier/bootstrap-db"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'railties'

  spec.add_development_dependency "activerecord"
  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "database_cleaner"
  spec.add_development_dependency "rspec-rails"
end
