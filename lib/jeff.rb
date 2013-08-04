# Our only external dependency. Excon is currently my preferred HTTP client in
# Ruby.
require 'excon'

# Standard library dependencies.
require 'base64'
require 'openssl'
require 'time'

# Jeff mixes in client behaviour for Amazon Web Services (AWS) that require
# Signature version 2 authentication.
#
# It's Jeff, as in Jeff Bezos.
module Jeff
  # Converts a query value to a sorted query string.
  Query = Struct.new(:values) do
    def to_s
      values
        .sort
        .map { |k, v| "#{k}=#{ Utils.escape(v) }" }
        .join('&')
    end
  end

  # Calculates a RFC 2104-compliant HMAC signature.
  module Signature
    SHA256 = OpenSSL::Digest::SHA256.new

    def self.calculate(secret, message)
      Base64.encode64(OpenSSL::HMAC.digest(SHA256, secret, message)).strip
    end
  end

  # Because Ruby's CGI escapes ~, we have to resort to writing our own escape.
  module Utils
    UNRESERVED = /([^\w.~-]+)/

    def self.escape(val)
      val.to_s.gsub(UNRESERVED) do
        '%' + $1.unpack('H2' * $1.bytesize).join('%').upcase
      end
    end
  end

  # Jeff's current version.
  VERSION = '0.6.4'

  # Amazon recommends to include a User-Agent header with every request to 
  # identify the application, its version number, programming language, and
  # host.
  #
  # If not happy, override.
  USER_AGENT = "Jeff/#{VERSION} (Language=Ruby; #{`hostname`.chomp})"

  def self.included(base)
    base.extend(ClassMethods)

    # Common parameters required by all AWS requests.
    #
    # Add other common parameters using `Jeff.params` if required in your
    # implementation.
    base.params(
      'AWSAccessKeyId'   => -> { aws_access_key_id },
      'SignatureVersion' => '2',
      'SignatureMethod'  => 'HmacSHA256',
      'Timestamp'        => -> { Time.now.utc.iso8601 }
    )
  end

  # A HTTP connection. It's reusable, which, as the author of Excon puts it, is
  # more performant!
  def connection
    @connection ||= Excon.new(endpoint,
      headers: { 'User-Agent' => USER_AGENT },
      expects: 200,
      omit_default_port: true
    )
  end

  # Accessors for required AWS attributes.
  attr_accessor :aws_endpoint, :aws_access_key_id, :aws_secret_access_key

  # We'll keep these around so we don't break dependent libraries.
  alias endpoint aws_endpoint
  alias endpoint= aws_endpoint=
  alias key aws_access_key_id
  alias key= aws_access_key_id=
  alias secret aws_secret_access_key
  alias secret= aws_secret_access_key=

  # Generate HTTP request verb methods.
  Excon::HTTP_VERBS.each do |method|
    eval <<-DEF
      def #{method}(options = {})
        options.store(:method, :#{method})
        connection.request(build_options(options))
      end
    DEF
  end

  private

  def build_options(options)
    if options[:body]
      options[:headers] ||= {}
      digest = Base64.encode64(OpenSSL::Digest::MD5.digest(options[:body])).strip
      options[:headers].store('Content-MD5', digest)
    end

    params = self.class.params.reduce({}) do |a, (k, v)|
      a.update k => (v.respond_to?(:call) ? instance_exec(&v) : v)
    end

    query = Query.new(params.merge(options.fetch(:query, {}))).to_s
    string_to_sign = [
      options[:method].upcase,
      connection.data[:host],
      options[:path] || connection.data[:path],
      query
    ].join("\n")
    signature = Signature.calculate(aws_secret_access_key, string_to_sign)

    options.update(query: [
       query,
       "Signature=#{Utils.escape(signature)}"
    ].join('&'))
  end

  module ClassMethods
    # Gets and optionally updates the default request parameters.
    def params(hsh = {})
      (@params ||= {}).update(hsh)
    end
  end
end
