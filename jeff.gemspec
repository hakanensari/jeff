# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require File.expand_path('../lib/jeff/version.rb', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['Hakan Ensari']
  gem.email         = ['hakan.ensari@papercavalier.com']
  gem.description   = %q{An Amazon Web Services client}
  gem.summary       = %q{AWS client}
  gem.homepage      = 'https://github.com/papercavalier/jeff'

  gem.files         = `git ls-files`.split($\)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = 'jeff'
  gem.require_paths = ['lib']
  gem.version       = Jeff::VERSION

  gem.add_dependency 'excon', '~> 0.25.0'

  gem.required_ruby_version = '>= 1.9'
end
