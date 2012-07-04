require 'base64'
require 'time'

require 'excon'

require 'jeff/version'

module Jeff
  MissingEndpoint = Class.new ArgumentError
  MissingKey      = Class.new ArgumentError
  MissingSecret   = Class.new ArgumentError

  SHA256 = OpenSSL::Digest::SHA256.new
  UNRESERVED = /([^\w.~-]+)/

  def self.included(base)
    base.extend ClassMethods
  end

  # Returns an Excon::Connection.
  def connection
    @connection ||= Excon.new endpoint, :headers => default_headers
  end

  # Returns the Hash default request parameters.
  def default_params
    self.class.params.reduce({}) do |a, (k, v)|
      a.update k => (v.is_a?(Proc) ? instance_eval(&v) : v)
    end
  end

  # Returns the Hash default headers.
  def default_headers
    self.class.headers
  end

  # Gets the String AWS endpoint.
  #
  # Raises a MissingEndpoint error if endpoint is missing.
  def endpoint
    @endpoint or raise MissingEndpoint
  end

  # Sets the String AWS endpoint.
  attr_writer :endpoint

  # Gets the String AWS access key id.
  #
  # Raises a MissingKey error if key is missing.
  def key
    @key or raise MissingKey
  end

  # Sets the String AWS access key id.
  attr_writer :key

  # Gets the String AWS secret key.
  #
  # Raises a MissingSecret error if secret is missing.
  def secret
    @secret or raise MissingSecret
  end

  # Sets the String AWS secret key.
  attr_writer :secret

  # Generate HTTP request verb methods that sign queries and then delegate
  # request to Excon.
  Excon::HTTP_VERBS. each do |method|
    eval <<-DEF
      def #{method}(opts = {}, &block)
        opts.update method: :#{method}
        connection.request sign opts, &block
      end
    DEF
  end

  # Internal: Builds a sorted query.
  #
  # hsh - A hash of query parameters specific to the request.
  #
  # Returns a query String.
  def build_query(hsh)
    default_params
      .merge(hsh)
      .map { |k, v| "#{k}=#{ escape v }" }
      .sort
      .join '&'
  end

  private

  def sign(opts)
    query = build_query opts[:query] || {}

    string_to_sign = [
      opts[:method],
      opts[:host] || connection.connection[:host],
      opts[:path] || connection.connection[:path],
      query
    ].join "\n"

    digest    = OpenSSL::HMAC.digest SHA256, secret, string_to_sign
    signature = Base64.encode64(digest).chomp

    opts.update query: [
       query,
       "Signature=#{escape signature}"
    ].join('&')
  end

  def escape(val)
    val.to_s.gsub(UNRESERVED) do
      '%' + $1.unpack('H2' * $1.bytesize).join('%').upcase
    end
  end

  module ClassMethods
    # Amazon recommends that libraries identify themselves via a User Agent.
    USER_AGENT = "Jeff/#{VERSION} (Language=Ruby; #{`hostname`.chomp})"

    # Gets/Updates the default headers.
    #
    # hsh - A Hash of headers.
    #
    # Returns the Hash headers.
    def headers(hsh = nil)
      @headers ||= { 'User-Agent' => USER_AGENT }
      @headers.update hsh if hsh

      @headers
    end

    # Gets/Updates the default request parameters.
    #
    # hsh - A Hash of parameters (default: nil).
    #
    # Returns the Hash parameters.
    def params(hsh = nil)
      @params ||= {
        'AWSAccessKeyId'   => Proc.new { key },
        'SignatureVersion' => '2',
        'SignatureMethod'  => 'HmacSHA256',
        'Timestamp'        => Proc.new { Time.now.utc.iso8601 }
      }
      @params.update hsh if hsh

      @params
    end
  end
end
