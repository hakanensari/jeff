require 'spec_helper'

module Jeff
  describe Client do
    before do
      @endpoint = 'http://slowapi.com/delay/0'

      @client = Client.new @endpoint
      @client.configure do |config|
        config.key    = 'key'
        config.secret = 'secret'
      end
    end

    describe '#<<' do
      it 'updates the request parameters' do
        @client << { 'Foo' => 1 }
        @client.params.should include 'Foo'
      end

      it 'updates the request body' do
        @client << 'foo'
        @client.body.should eql 'foo'
      end

      it 'updates the request chunked body' do
        chunker = lambda {}
        @client << chunker
        @client.chunker.should eql chunker
      end
    end

    describe '#params' do
      subject { @client.params }

      it 'includes a key' do
        should include 'AWSAccessKeyId'
      end

      it 'includes a signature version' do
        should include 'SignatureVersion'
      end

      it 'includes a signature method' do
        should include 'SignatureMethod'
      end

      it 'includes a timestamp' do
        should include 'Timestamp'
      end
    end

    describe '#url' do
      subject { @client.url }

      it 'includes the endpoint' do
        should include @endpoint
      end

      it 'sorts the parameters' do
        @client << { 'Z' => 1, 'A' => 1 }
        should match /\?A=[^&]+/
      end

      it 'is signed' do
        should match /Signature=[^&]+$/
      end
    end

    describe '#request' do
      context 'given no body or chunker' do
        it 'makes a GET request' do
          Excon.stub({ :method => :get }, { :body => 'get' })
          @client.request(:mock => true).body.should eql 'get'
        end
      end

      context 'given a body' do
        it 'makes a POST request' do
          Excon.stub({ :method => :post }, { :body => 'post' })
          @client << 'foo'
          @client.request(:mock => true).body.should eql 'post'
        end
      end
    end
  end
end
