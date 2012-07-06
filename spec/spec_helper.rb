begin
  require 'pry'
  require 'pry-doc'
rescue LoadError
end
require 'rspec'

require 'jeff'

RSpec.configure do |c|
  c.order = :random
end
