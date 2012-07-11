require 'spec_helper'

describe Jeff do
  let(:klass)  { Class.new { include Jeff } }
  let(:client) { klass.new }

  describe '.headers' do
    subject { klass.headers }

    it { should have_key 'User-Agent' }

    it 'should be configurable' do
      klass.instance_eval do
        headers 'Foo' => 'bar'
      end

      should have_key 'Foo'
    end
  end

  describe '.params' do
    subject { klass.params }

    it { should have_key 'AWSAccessKeyId' }

    it { should have_key 'SignatureMethod' }

    it { should have_key 'SignatureVersion' }

    it { should have_key 'Timestamp' }

    it 'should be configurable' do
      klass.instance_eval do
        params 'Foo' => 'bar'
      end

      should have_key 'Foo'
    end
  end

  describe '#endpoint' do
    it 'should require a value' do
      expect { client.endpoint }.to raise_error Jeff::MissingEndpoint
    end
  end

  describe '#key' do
    it 'should require a value' do
      expect { client.key }.to raise_error Jeff::MissingKey
    end
  end

  describe '#secret' do
    it 'should require a value' do
      expect { client.secret }.to raise_error Jeff::MissingSecret
    end
  end

  context 'given a key' do
    before do
      client.key = 'key'
    end

    describe '#default_params' do
      subject { client.default_params }

      it 'should include the key' do
        subject['AWSAccessKeyId'].should eql client.key
      end

      it 'should generate a timestamp' do
        subject['Timestamp'].should be_a String
      end
    end

    describe '#build_query' do
      subject { client.build_query 'A10' => 1, 'A1' => 1 }

      it 'should include default parameters' do
        should match /Timestamp/
      end

      it 'should sort lexicographically' do
        should match /^A1=1&A10=/
      end
    end
  end

  context 'given an endpoint' do
    before do
      client.endpoint = 'http://slowapi.com/delay/0'
    end

    describe "#connection" do
      subject { client.connection }
      let(:headers) { subject.connection[:headers] }

      it { should be_an Excon::Connection }

      it 'should set default headers' do
        headers.should eq klass.headers
      end

      it 'should cache itself' do
        subject.should be client.connection
      end
    end
  end

  context 'given an endpoint, key, and secret' do
    before do
      client.endpoint = 'http://slowapi.com/delay/0'
      client.key = 'key'
      client.secret = 'secret'
    end

    Excon::HTTP_VERBS.each do |method|
      describe "##{method}" do
        subject { client.send(method, mock: true).body.root['request'] }

        before do
          Excon.stub({ method: method.to_sym }) do |params|
            { body: "<request>#{params[:method]}</request>" }
          end
        end

        after { Excon.stubs.clear }

        it "should make a #{method.upcase} request" do
          should eql method
        end
      end
    end

    context 'given a failed request' do
      before do
        has_run = false
        Excon.stub({ method: :get }) do |params|
          if has_run
            { status: 200 }
          else
            has_run = true
            raise Excon::Errors::SocketError.new Exception.new 'Mock Error'
          end
        end
      end

      after { Excon.stubs.clear }

      it 'should retry' do
        client.get(mock: true).status.should be 200
      end
    end

    context 'given a malformed XML' do
      before do
        Excon.stub({ method: :get }) do |params|
          { body: "\n<?xml version=\"1.0\" ?><foo/>" }
        end
      end

      after { Excon.stubs.clear }

      it 'should not raise an error' do
        client.get mock: true
      end
    end
  end
end
