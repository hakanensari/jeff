# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require File.expand_path('../lib/jeff/version.rb', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['Hakan Ensari']
  gem.email         = ['hakan.ensari@papercavalier.com']
  gem.description   = %q{A minimum-viable Amazon Web Services (AWS) client}
  gem.summary       = %q{An AWS client}
  gem.homepage      = 'https://github.com/hakanensari/jeff'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = 'jeff'
  gem.require_paths = ['lib']
  gem.version       = Jeff::VERSION

  gem.add_dependency             'excon', '~> 0.14'
  gem.add_development_dependency 'rake',  '~> 0.9'
  gem.add_development_dependency 'rspec', '~> 2.10'
end
