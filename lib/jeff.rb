require 'base64'
require 'digest/md5'
require 'excon'
require 'openssl'
require 'time'

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

  module Signature
    SHA256 = OpenSSL::Digest::SHA256.new

    def self.calculate(secret, message)
      OpenSSL::HMAC.hexdigest(SHA256, secret, message)
    end
  end

  Query = Struct.new(:values) do
    def to_s
      values
        .sort
        .map { |k, v| "#{k}=#{ Utils.escape(v) }" }
        .join('&')
    end
  end

  # Amazon recommends to include a User-Agent header that identifies the
  # application, its version number, and programming language.
  USER_AGENT = "Jeff/#{VERSION} (Language=Ruby; #{`hostname`.chomp})"

  def self.included(base)
    base.extend(ClassMethods)

    # These are the common parameters required by all AWS requests.
    base.params(
      'AWSAccessKeyId'   => -> { key },
      'SignatureVersion' => '2',
      'SignatureMethod'  => 'HmacSHA256',
      'Timestamp'        => -> { Time.now.utc.iso8601 }
    )
  end

  # Internal: Build a sorted query.
  #
  # hsh - A hash of query parameters specific to the request.
  #
  # Returns a query String.
  def build_query(hsh)
    Query.new(params.merge(hsh)).to_s
  end

  # Internal: Returns an Excon::Connection.
  def connection
    @connection ||= Excon.new(endpoint,
      headers: { 'User-Agent' => USER_AGENT },
      expects: 200,
      omit_default_port: true
    )
  end

  # Gets/Sets the String AWS endpoint.
  attr_accessor :endpoint

  # Gets/Sets the String AWS access key id.
  attr_accessor :key

  # Gets/Sets the String AWS secret key.
  attr_accessor :secret

  # Generate HTTP request verb methods.
  Excon::HTTP_VERBS.each do |method|
    eval <<-DEF
      def #{method}(opts = {})
        opts.store(:method, :#{method})
        connection.request(build_options(opts))
      end
    DEF
  end

  private

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
    signature = Signature.calculate(secret, string_to_sign)

    opts.update(query: [
       query,
       "Signature=#{Utils.escape(signature)}"
    ].join('&'))
  end

  module ClassMethods
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
