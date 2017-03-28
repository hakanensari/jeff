# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require File.expand_path("../lib/jeff/version.rb", __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Hakan Ensari"]
  gem.email         = ["me@hakanensari.com"]
  gem.description   = %q{An Amazon Web Services client}
  gem.summary       = %q{An AWS client}
  gem.homepage      = "https://github.com/hakanensari/jeff"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($\)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "jeff"
  gem.require_paths = ["lib"]
  gem.version       = Jeff::VERSION

  gem.add_dependency "excon"
  gem.add_development_dependency "minitest"
  gem.add_development_dependency "rake"

  gem.required_ruby_version = ">= 1.9"
end
