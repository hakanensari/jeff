require 'base64'
require 'forwardable'
require 'time'

require 'excon'

require 'jeff/version'
require 'jeff/query_builder'
require 'jeff/user_agent'
require 'jeff/client'
require 'jeff/signature'

module Jeff
  class << self
    extend Forwardable

    def_delegator Client, :new
  end
end
