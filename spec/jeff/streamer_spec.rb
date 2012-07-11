require 'spec_helper'

module Jeff
  describe Streamer do
    let(:streamer) { Streamer.new }

    let(:xml) do
      %{
        <?xml version="1.0" ?>
        <foo>
          <bar>
            <baz>1</baz>
            <qux>2</qux>
            <qux>3</qux>
          </bar>
          <quux>
            <qux>4</qux>
          </quux>
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

    describe '#find' do
      before do
        streamer.call xml, 0, xml.size
      end

      it 'should find a node' do
        streamer.find('baz').should eql ['1']
      end

      it 'should find a collection of nodes' do
        streamer.find('qux').should eql ['2', '3', '4']
      end

      it 'should be empty if no matches found' do
        streamer.find('corge').should be_empty
      end
    end
  end
end
