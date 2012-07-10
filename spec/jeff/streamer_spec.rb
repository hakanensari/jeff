require 'spec_helper'

module Jeff
  describe Streamer do
    let(:streamer) { Streamer.new }
    let(:xml) { '<?xml version="1.0"?><foo>bar</foo>' }

    it 'should parse XML' do
      streamer << xml
      streamer.finish.should eq({ 'foo' => 'bar' })
    end
  end
end
