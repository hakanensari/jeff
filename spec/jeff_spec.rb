require 'minitest/autorun'
require 'minitest/pride'
require 'jeff'

Excon.defaults[:mock] = true

describe Jeff do
  before do
    @klass = Class.new do
      include Jeff
    end
  end

  it 'has the required request query parameters' do
    %w(AWSAccessKeyId SignatureMethod SignatureVersion Timestamp)
      .each { |key| assert @klass.params.has_key?(key) }
  end

  it 'configures the request query parameters' do
    @klass.instance_eval do
      params 'Foo' => 'bar'
    end
    assert @klass.params.has_key?('Foo')
  end

  it 'requires a signature' do
    sig = Jeff::Signature.new(nil)
    proc { sig.sign('foo') }.must_raise ArgumentError
  end

  it 'sorts the request query parameters of the client lexicographically' do
    query = Jeff::Query.new('A10' => 1, 'A1' => 1)
    query.to_s.must_equal('A1=1&A10=1')
  end

  it 'sets a User-Agent header for the client connection' do
    client = @klass.new
    client.aws_endpoint = 'http://example.com/'
    client.connection.data[:headers]['User-Agent'].wont_be_nil
  end

  Excon::HTTP_VERBS.each do |method|
    it "makes a #{method.upcase} request" do
      Excon.stub({ }, { status: 200 })
      client = @klass.new
      client.aws_endpoint = 'http://example.com/'
      client.aws_access_key_id = 'foo'
      client.aws_secret_access_key = 'bar'
      client.send(method).status.must_equal 200
      Excon.stubs.clear
    end
  end

  it 'adds a Content-MD5 request header if there is a request body' do
    Excon.stub({ }) do |params|
      { body: params[:headers]['Content-MD5'] }
    end
    client = @klass.new
    client.aws_endpoint = 'http://example.com/'
    client.aws_access_key_id = 'foo'
    client.aws_secret_access_key = 'bar'
    client.post(body: 'foo').body.wont_be_empty
    Excon.stubs.clear
  end
end
