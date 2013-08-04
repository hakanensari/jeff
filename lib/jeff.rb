require 'base64'
require 'digest/md5'
require 'excon'
require 'time'

require 'jeff/secret'
require 'jeff/version'

# Mixes in Amazon Web Services (AWS) client behaviour.
module Jeff
  module Utils
    UNRESERVED = /([^\w.~-]+)/

    def self.escape(val)
      val.to_s.gsub(UNRESERVED) do
        '%' + $1.unpack('H2' * $1.bytesize).join('%').upcase
      end
    end
  end

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
      .map { |k, v| "#{k}=#{ Utils.escape(v) }" }
      .join('&')
  end

  # Internal: Returns an Excon::Connection.
  def connection
    @connection ||= Excon.new(endpoint, headers: headers, expects: 200)
  end

  # Gets/Sets the String AWS endpoint.
  attr_accessor :endpoint

  # Gets/Sets the String AWS access key id.
  attr_accessor :key

  # Internal: Gets the Jeff::Secret.
  #
  # Raises a MissingSecret error if secret is missing.
  def secret
    @secret
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
        opts.update(:method => :#{method}, :omit_default_port => true)
        connection.request(build_options(opts))
      end
    DEF
  end

  private

  def headers
    self.class.headers
  end

  def params
    self.class.params.reduce({}) do |a, (k, v)|
      a.update k => (v.respond_to?(:call) ? instance_exec(&v) : v)
    end
  end

  def build_options(opts)
    if opts[:body]
      opts[:headers] ||= {}
      opts[:headers].update('Content-MD5' => calculate_md5(opts[:body]))
    end

    sign(opts)
  end

  def calculate_md5(body)
    Base64.encode64(Digest::MD5.digest(body)).strip
  end

  def sign(opts)
    query = build_query(opts[:query] || {})

    string_to_sign = [
      opts[:method].upcase,
      connection.data[:host],
      opts[:path] || connection.data[:path],
      query
    ].join("\n")
    signature = secret.sign(string_to_sign)

    opts.update(query: [
       query,
       "Signature=#{Utils.escape(signature)}"
    ].join('&'))
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
