require 'spec_helper'

module Jeff
  describe Serviceable do
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
        expect { client.endpoint }.to raise_error Serviceable::MissingEndpoint
      end
    end

    describe '#key' do
      it 'should require a value' do
        expect { client.key }.to raise_error Serviceable::MissingKey
      end
    end

    describe '#secret' do
      it 'should require a value' do
        expect { client.secret }.to raise_error Serviceable::MissingSecret
      end
    end

    context 'given a key' do
      before do
        client.key = 'key'
      end

      describe '#params' do
        subject { client.params }

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
          should match(/Timestamp/)
        end

        it 'should sort lexicographically' do
          should match(/^A1=1&A10=/)
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
          subject do
            client.send(method, mock: true).body
          end

          before do
            Excon.stub({ method: method.to_sym }) do |params|
              { body: method, status: 200 }
            end
          end

          after { Excon.stubs.clear }

          it "should make a #{method.upcase} request" do
            should eql method
          end
        end
      end

      context 'given an HTTP status error' do
        before do
          Excon.stub({ method: :get }) do
            { status: 503 }
          end
        end

        after { Excon.stubs.clear }

        it "should raise an error" do
          expect {
            client.get mock: true
          }.to raise_error Excon::Errors::HTTPStatusError
        end
      end
    end
  end
end
