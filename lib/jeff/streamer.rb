require 'jeff/document'

module Jeff
  class Streamer
    def initialize
      @parser = Nokogiri::XML::SAX::PushParser.new Document.new
    end

    def call(chunk, remaining_bytes, total_bytes)
      @parser << chunk.sub(/\n/, '')
      @parser.finish if remaining_bytes == 0
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
