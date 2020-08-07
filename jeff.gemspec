# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require File.expand_path('lib/jeff/version.rb', __dir__)

Gem::Specification.new do |gem|
  gem.name          = 'jeff'
  gem.authors       = ['Hakan Ensari']
  gem.email         = ['me@hakanensari.com']
  gem.description   = 'An Amazon Web Services client'
  gem.summary       = 'An AWS client'
  gem.homepage      = 'https://github.com/hakanensari/jeff'
  gem.license       = 'MIT'

  gem.files         = Dir.glob('lib/**/*') + %w[LICENSE README.md]
  gem.version       = Jeff::VERSION

  gem.add_dependency 'excon'
  gem.add_development_dependency 'minitest'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rubocop'

  gem.required_ruby_version = '>= 2.5'
end
