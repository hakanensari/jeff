require 'base64'
require 'digest/md5'
require 'excon'
require 'time'

require 'jeff/secret'
require 'jeff/version'

# Mixes in Amazon Web Services (AWS) client behaviour.
module Jeff
  MissingEndpoint = Class.new(ArgumentError)
  MissingKey      = Class.new(ArgumentError)
  MissingSecret   = Class.new(ArgumentError)

  UNRESERVED = /([^\w.~-]+)/

  # A User-Agent header that identifies the application, its version number,
  # and programming language.
  #
  # Amazon recommends to include one in requests to AWS endpoints.
  USER_AGENT = "Jeff/#{VERSION} (Language=Ruby; #{`hostname`.chomp})"

  def self.included(base)
    base.extend ClassMethods

    base.headers 'User-Agent'       => USER_AGENT

    base.params  'AWSAccessKeyId'   => -> { key },
                 'SignatureVersion' => '2',
                 'SignatureMethod'  => 'HmacSHA256',
                 'Timestamp'        => -> { Time.now.utc.iso8601 }
  end

  # Internal: Build a sorted query.
  #
  # hsh - A hash of query parameters specific to the request.
  #
  # Returns a query String.
  def build_query(hsh)
    params
      .merge(hsh)
      .sort
      .map { |k, v| "#{k}=#{ escape(v) }" }
      .join('&')
  end

  # Internal: Returns an Excon::Connection.
  def connection
    @connection ||= Excon.new(endpoint, headers: headers, expects: 200)
  end

  # Internal: Gets the String AWS endpoint.
  #
  # Raises a MissingEndpoint error if endpoint is missing.
  def endpoint
    @endpoint or raise MissingEndpoint
  end

  # Sets the String AWS endpoint.
  attr_writer :endpoint

  # Internal: Returns the Hash default headers.
  def headers
    self.class.headers
  end

  # Internal: Gets the String AWS access key id.
  #
  # Raises a MissingKey error if key is missing.
  def key
    @key or raise MissingKey
  end

  # Sets the String AWS access key id.
  attr_writer :key

  # Internal: Returns the Hash default request parameters.
  def params
    self.class.params.reduce({}) do |a, (k, v)|
      a.update k => (v.respond_to?(:call) ? instance_exec(&v) : v)
    end
  end

  # Internal: Gets the Jeff::Secret.
  #
  # Raises a MissingSecret error if secret is missing.
  def secret
    @secret or raise MissingSecret
  end

  # Sets the AWS secret key.
  #
  # key - A String secret.
  #
  # Returns a Jeff::Secret.
  def secret=(key)
    @secret = Secret.new(key)
  end

  # Generate HTTP request verb methods.
  Excon::HTTP_VERBS.each do |method|
    eval <<-DEF
      def #{method}(opts = {})
        opts.update :method => :#{method}
        connection.request(build_options(opts))
      end
    DEF
  end

  private

  def build_options(opts)
    opts[:headers] ||= {}
    opts[:headers].update('Host' => connection_host)

    if opts[:body]
      opts[:headers].update('Content-MD5' => calculate_md5(opts[:body]))
    end

    sign(opts)
  end

  def calculate_md5(body)
    Base64.encode64(Digest::MD5.digest(body)).strip
  end

  def connection_host
    connection.data[:host]
  end

  def connection_path
    connection.data[:path]
  end

  def escape(val)
    val.to_s.gsub(UNRESERVED) do
      '%' + $1.unpack('H2' * $1.bytesize).join('%').upcase
    end
  end

  def sign(opts)
    query = build_query(opts[:query] || {})

    string_to_sign = [
      opts[:method].upcase,
      connection_host,
      opts[:path] || connection_path,
      query
    ].join("\n")
    signature = secret.sign(string_to_sign)

    opts.update query: [
       query,
       "Signature=#{escape(signature)}"
    ].join('&')
  end

  module ClassMethods
    # Gets/Updates the default headers.
    #
    # hsh - A Hash of headers.
    #
    # Returns the Hash headers.
    def headers(hsh = nil)
      @headers ||= {}
      @headers.update(hsh) if hsh

      @headers
    end

    # Gets/Updates the default request parameters.
    #
    # hsh - A Hash of parameters (default: nil).
    #
    # Returns the Hash parameters.
    def params(hsh = nil)
      @params ||= {}
      @params.update(hsh) if hsh

      @params
    end
  end
end
