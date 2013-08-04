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

  it 'sorts the request query parameters of the client lexicographically' do
    client = @klass.new
    client.key = 'foo'
    query = client.build_query 'A10' => 1, 'A1' => 1

    query.must_match(/^A1=1&A10=.*Timestamp/)
  end

  it 'sets a User-Agent header for the client connection' do
    client = @klass.new
    client.endpoint = 'http://example.com/'

    client.connection.data[:headers]['User-Agent'].wont_be_nil
  end

  Excon::HTTP_VERBS.each do |method|
    it "makes a #{method.upcase} request" do
      Excon.stub({ }, { status: 200 })

      client = @klass.new
      client.endpoint = 'http://example.com/'
      client.key = 'foo'
      client.secret = 'bar'

      client.send(method).status.must_equal 200

      Excon.stubs.clear
    end
  end

  it 'adds a Content-MD5 request header if there is a request body' do
    Excon.stub({ }) do |params|
      { body: params[:headers]['Content-MD5'] }
    end

    client = @klass.new
    client.endpoint = 'http://example.com/'
    client.key = 'foo'
    client.secret = 'bar'

    client.post(body: 'foo').body.wont_be_empty

    Excon.stubs.clear
  end
end
