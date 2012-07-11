require 'forwardable'

require 'jeff/document'

module Jeff
  class Streamer
    extend Forwardable

    def_delegators :@parser, :<<, :finish

    def initialize
      @parser = Nokogiri::XML::SAX::PushParser.new @doc = Document.new
    end

    # Queries response for a key.
    #
    # key - A String key.
    #
    # Returns an Array of matches.
    def find(key, node = nil)
      node ||= root

      case node
      when Array
        node
          .map { |val| find key, val }
          .compact
          .flatten
      when Hash
        if node.has_key? key
          [node[key]]
        else
          node
            .values
            .map { |val| find key, val }
            .compact
            .flatten
        end
      end
    end

    def root
      @parser.document.root
    end
  end
end
