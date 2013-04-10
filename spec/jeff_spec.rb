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

  it 'has a User-Agent request header' do
    assert @klass.headers.has_key?('User-Agent')
  end

  it 'configures request headers' do
    @klass.instance_eval do
      headers 'Foo' => 'bar'
    end

    assert @klass.headers.has_key?('Foo')
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

  it 'requires an endpoint' do
    proc { @klass.new.endpoint }.must_raise Jeff::MissingEndpoint
  end

  it 'requires a key' do
    proc { @klass.new.key }.must_raise Jeff::MissingKey
  end

  it 'requires a secret' do
    proc { @klass.new.secret }.must_raise Jeff::MissingSecret
  end

  it 'sorts the request query parameters of the client lexicographically' do
    client = @klass.new
    client.key = 'foo'
    query = client.build_query 'A10' => 1, 'A1' => 1

    query.must_match(/^A1=1&A10=.*Timestamp/)
  end

  it 'sets the request headers of the client connection' do
    client = @klass.new
    client.endpoint = 'http://example.com/'

    client.connection.data[:headers].must_equal @klass.headers
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
