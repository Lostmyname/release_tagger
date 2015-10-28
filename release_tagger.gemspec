# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'release_tagger/version'

Gem::Specification.new do |spec|
  spec.name          = "release_tagger"
  spec.version       = ReleaseTagger::VERSION
  spec.authors       = ["Simon Coffey", "Nadir Lloret"]
  spec.email         = ["dev@lostmy.name"]
  spec.license       = "MIT"

  spec.summary       = %q{Helpers for managing a git tag-based release workflow integrated with packagecloud}
  spec.description   = %q{A set of helpers for tagging releases and logging changes between releases}
  spec.homepage      = "https://github.com/Lostmyname/release_tagger"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake",    "~> 10.0"
  spec.add_development_dependency "rspec",   "~> 3.3", ">= 3.3.0"
  spec.add_development_dependency "rubocop", "~> 0.32.1"
end
