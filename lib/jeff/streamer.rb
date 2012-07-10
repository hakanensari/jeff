require 'forwardable'

require 'jeff/body'

module Jeff
  class Streamer
    extend Forwardable

    def_delegator :@parser, :<<

    # Creates a new Streamer.
    def initialize
      @body   = Body.new
      @parser = Nokogiri::XML::SAX::PushParser.new @body
    end

    # Finishes parsing.
    #
    # Returns the Hash body.
    def finish
      @parser.finish
      @body.root
    end
  end
end
