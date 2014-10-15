require "minitest/autorun"
require "minitest/pride"
require_relative "../lib/jeff"

class TestJeff < Minitest::Test
  def setup
    @klass = Class.new { include Jeff }
  end

  def test_delegates_unset_aws_credential_to_env_vars
    key = "123456"
    client = @klass.new
    %w(aws_access_key_id aws_secret_access_key).each do |attr|
      ENV[attr.upcase] = key
      assert_equal key, client.send(attr)
      ENV[attr.upcase] = nil
      refute_equal key, client.send(attr)
    end
  end

  def test_has_required_request_query_parameters
    %w(AWSAccessKeyId SignatureMethod SignatureVersion Timestamp).each do |key|
      assert @klass.params.has_key?(key)
    end
  end

  def test_configures_request_query_parameters
    @klass.instance_eval do
      params "Foo" => "bar"
    end
    assert @klass.params.has_key?("Foo")
  end

  def test_requires_signature
    signature = Jeff::Signature.new(nil)
    assert_raises(ArgumentError) { signature.sign("foo") }
  end

  def test_sorts_request_query_parameters_lexicographically
    query = Jeff::Query.new("A10" => 1, "A1" => 1)
    assert_equal "A1=1&A10=1", query.to_s
  end

  def test_sets_user_agent_header
    client = @klass.new
    client.aws_endpoint = "http://example.com/"
    assert_includes client.connection.data[:headers]["User-Agent"], "Jeff"
  end

  def test_allows_customizing_user_agent
    @klass.user_agent = "CustomApp/1.0"
    client = @klass.new
    client.aws_endpoint = "http://example.com/"
    assert_equal "CustomApp/1.0", client.connection.data[:headers]["User-Agent"]
  end

  def test_does_not_escape_tilde
    assert_equal "~%2C", Jeff::Utils.escape("~,")
  end

  Excon::HTTP_VERBS.each do |method|
    define_method "test_makes_#{method}_request" do
      Excon.stub({ }, { status: 200 })
      client = @klass.new
      client.aws_endpoint = "http://example.com/"
      client.aws_access_key_id = "foo"
      client.aws_secret_access_key = "bar"
      assert_equal 200, client.send(method, mock: true).status
      Excon.stubs.clear
    end
  end

  def test_adds_content_md5_request_header_if_given_a_request_body
    Excon.stub({ }) do |params|
      { body: params[:headers]["Content-MD5"] }
    end
    client = @klass.new
    client.aws_endpoint = "http://example.com/"
    client.aws_access_key_id = "foo"
    client.aws_secret_access_key = "bar"
    refute_empty client.post(body: "foo", mock: true).body
    Excon.stubs.clear
  end

  def test_integration
    client = @klass.new
    client.aws_access_key_id = "foo"
    client.aws_secret_access_key = "bar"
    client.aws_endpoint = "https://mws.amazonservices.com/Sellers/2011-07-01"
    res = client.post(query: { "Action" => "GetServiceStatus"})
    assert_equal 200, res.status
  end
end
