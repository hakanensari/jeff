require 'jeff/document'

module Jeff
  class Streamer
    def initialize
      @parser = Nokogiri::XML::SAX::PushParser.new Document.new
    end

    def call(chunk, remaining_bytes, total_bytes)
      @parser << chunk.sub(/^\n/, '')
      @parser.finish if remaining_bytes == 0
    end

    def document
      @parser.document
    end

    def root
      document.root
    end
  end
end
