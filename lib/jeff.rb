# Jeff's only external dependency.
require "excon"

# Standard library dependencies.
require "base64"
require "openssl"
require "time"

require "jeff/version"

# Jeff mixes in client behaviour for Amazon Web Services (AWS) that require
# Signature version 2 authentication.
module Jeff
  # Converts query field-value pairs to a sorted query string.
  class Query
    attr :values

    def initialize(values)
      @values = values
    end

    def to_s
      values.sort.map { |k, v| "#{k}=#{ Utils.escape(v) }" }.join("&")
    end
  end

  # Calculates an MD5sum for file being uploaded.
  class Content
    attr :body

    def initialize(body)
      @body = body
    end

    def md5
      Base64.encode64(OpenSSL::Digest::MD5.digest(body)).strip
    end
  end

  # Signs an AWS request.
  class Signer
    attr :method, :host, :path, :query_string

    def initialize(method, host, path, query_string)
      @method = method.upcase
      @host = host
      @path = path
      @query_string = query_string
    end

    def sign_with(aws_secret_access_key)
      Signature.new(aws_secret_access_key).sign(string_to_sign)
    end

    def string_to_sign
      [method, host, path, query_string].join("\n")
    end
  end

  # Calculates an RFC 2104-compliant HMAC signature.
  class Signature
    SHA256 = OpenSSL::Digest::SHA256.new

    def initialize(secret)
      @secret = secret
    end

    def sign(message)
      Base64.encode64(OpenSSL::HMAC.digest(SHA256, secret, message)).strip
    end

    def secret
      @secret or raise ArgumentError.new("Missing secret")
    end
  end

  # Because Ruby's CGI escapes tilde, use a custom escape.
  module Utils
    UNRESERVED = /([^\w.~-]+)/

    def self.escape(val)
      val.to_s.gsub(UNRESERVED) do
        "%" + $1.unpack("H2" * $1.bytesize).join("%").upcase
      end
    end
  end

  def self.included(base)
    base.extend(ClassMethods)

    # Common parameters required by all AWS requests.
    #
    # Add other common parameters using `Jeff.params` if required in your
    # implementation.
    base.params(
      "AWSAccessKeyId"   => -> { aws_access_key_id },
      "SignatureVersion" => "2",
      "SignatureMethod"  => "HmacSHA256",
      "Timestamp"        => -> { Time.now.utc.iso8601 }
    )
  end

  # A reusable HTTP connection.
  def connection
    @connection ||= Excon.new(aws_endpoint,
      headers: { "User-Agent" => self.class.user_agent },
      expects: 200,
      omit_default_port: true
    )
  end

  attr_accessor :aws_endpoint

  attr_writer :aws_access_key_id, :aws_secret_access_key

  def aws_access_key_id
    @aws_access_key_id || ENV["AWS_ACCESS_KEY_ID"]
  end

  def aws_secret_access_key
    @aws_secret_access_key || ENV["AWS_SECRET_ACCESS_KEY"]
  end

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
    # Add Content-MD5 header if uploading a file.
    if options.has_key?(:body)
      md5 = Content.new(options[:body]).md5
      (options[:headers] ||= {}).store("Content-MD5", md5)
    end

    # Build query string.
    query_values = default_query_values.merge(options.fetch(:query, {}))
    query_string = Query.new(query_values).to_s

    # Generate signature.
    signature = Signer
      .new(options[:method], connection.data[:host], options[:path] || connection.data[:path], query_string)
      .sign_with(aws_secret_access_key)

    # Return options after appending an escaped signature to query.
    options.merge(query: "#{query_string}&Signature=#{Utils.escape(signature)}")
  end

  def default_query_values
    self.class.params.reduce({}) { |a, (k, v)|
      a.update(k => (v.respond_to?(:call) ? instance_exec(&v) : v))
    }
  end

  module ClassMethods
    # Gets/updates default request parameters.
    def params(hsh = {})
      (@params ||= {}).update(hsh)
    end

    def user_agent
      @user_agent ||= default_user_agent

    end

    def user_agent=(user_agent)
      @user_agent = user_agent
    end

    private

    # Amazon recommends to include a User-Agent header with every request to
    # identify the application, its version number, programming language, and
    # host.
    def default_user_agent
      "Jeff/#{VERSION} (Language=Ruby; #{`hostname`.chomp})"
    end
  end
end
