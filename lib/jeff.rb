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
      values.sort.map { |k, v| "#{k}=#{ Utils.escape(v) }" }.join('&')
    end
  end

  # Calculates an MD5sum for file being uploaded.
  Content = Struct.new(:body) do
    def md5
      Base64.encode64(OpenSSL::Digest::MD5.digest(body)).strip
    end
  end

  # Signs an AWS request.
  Request = Struct.new(:method, :host, :path, :query_string) do
    def sign(aws_secret_access_key)
      Signature.new(aws_secret_access_key).sign(string_to_sign)
    end

    def string_to_sign
      [method, host, path, query_string].join("\n")
    end
  end

  # Calculates a RFC 2104-compliant HMAC signature.
  Signature = Struct.new(:secret) do
    SHA256 = OpenSSL::Digest::SHA256.new

    def sign(message)
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
    # Add a Content-MD5 header if we're uploading a file.
    if options.has_key?(:body)
      md5 = Content.new(options[:body]).md5
      (options[:headers] ||= {}).store('Content-MD5', md5)
    end

    # Build the query string.
    values = self.class.params
      .reduce({}) { |a, (k, v)|
        a.update(k => (v.respond_to?(:call) ? instance_exec(&v) : v))
      }
      .merge(options.fetch(:query, {}))
    query_string = Query.new(values).to_s

    # Generate a signature.
    signature = Request
      .new(
        options[:method].upcase,
        connection.data[:host],
        options[:path] || connection.data[:path],
        query_string
      )
      .sign(aws_secret_access_key)

    # Return options after appending an escaped signature to query.
    options.update(query: "#{query_string}&Signature=#{Utils.escape(signature)}")
  end

  module ClassMethods
    # Gets and optionally updates the default request parameters.
    def params(hsh = {})
      (@params ||= {}).update(hsh)
    end
  end
end
