require 'forwardable'

require 'jeff/document'

module Jeff
  class Streamer
    extend Forwardable

    def_delegators :@parser, :<<, :finish
    def_delegators :@doc, :root

    def initialize
      @parser = Nokogiri::XML::SAX::PushParser.new @doc = Document.new
    end

    # Queries response for a key.
    #
    # key - A String key.
    #
    # Returns a String or Hash match, an Array of matches, or nil if no matches
    # are found.
    def find(key, node = nil)
      node ||= root

      case node
      when Array
        ret = node.map { |val| find key, val }.compact
        ret.empty? ? nil :ret
      when Hash
        if node.has_key? key
          node.fetch key
        else
          node.values.map { |val| find key, val }.compact.first
        end
      end
    end
  end
end
