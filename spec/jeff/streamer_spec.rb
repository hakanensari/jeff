require 'spec_helper'

module Jeff
  describe Streamer do
    let(:streamer) { Streamer.new }

    let(:xml) do
      %{
        <?xml version="1.0" ?>
        <foo>
          <bar>1</bar>
        </foo>
      }.strip.gsub />\s+</, '><'
    end

    it 'should parse a stream' do
      bytes_sent  = 0
      total_bytes = xml.size

      xml.scan(/.{1,8}/m).each do |chunk|
        bytes_sent += chunk.size
        streamer.call chunk, total_bytes - bytes_sent, total_bytes
      end

      streamer.root.should have_key 'foo'
    end
  end
end
