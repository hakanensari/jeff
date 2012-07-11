require 'spec_helper'

module Jeff
  describe Streamer do
    let(:streamer) { Streamer.new }
    let(:xml) do %{
      <?xml version="1.0" ?>
        <foo>
          <bar>
            <baz>1</baz>
            <baz>2</baz>
            <qux>3</qux>
          </bar>
        </foo>
      }.strip.gsub />\s+</, '><'
    end

    it 'should parse a stream' do
      xml.scan(/.{1,8}/m)
         .each { |chunk| streamer << chunk }
      streamer.finish
      streamer.root.should have_key 'foo'
    end

    describe '#find' do
      before do
        streamer << xml
        streamer.finish
      end

      it 'should find a node' do
        streamer.find('qux').should eql '3'
      end

      it 'should find a collection of nodes' do
        streamer.find('baz').should eql ['1', '2']
      end

      it 'should be nil if no matches found' do
        streamer.find('quux').should be_nil
      end
    end
  end
end
