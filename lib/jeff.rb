require 'base64'
require 'digest/md5'
require 'excon'
require 'openssl'
require 'time'

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

  # Jeff's version.
  VERSION = '0.6.4'

  # Amazon recommends to include a User-Agent header that identifies the
  # application, its version number, and programming language.
  USER_AGENT = "Jeff/#{VERSION} (Language=Ruby; #{`hostname`.chomp})"

  def self.included(base)
    base.extend(ClassMethods)

    # These are the common parameters required by all AWS requests.
    base.params(
      'AWSAccessKeyId'   => -> { aws_access_key_id },
      'SignatureVersion' => '2',
      'SignatureMethod'  => 'HmacSHA256',
      'Timestamp'        => -> { Time.now.utc.iso8601 }
    )
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
  #
  # This, in URL parlance, is the scheme and the host.
  attr_accessor :aws_endpoint
  alias endpoint aws_endpoint
  alias endpoint aws_endpoint

  # Gets/Sets the String AWS access key id.
  attr_accessor :aws_access_key_id
  alias key aws_access_key_id
  alias key= aws_access_key_id=

  # Gets/Sets the String AWS secret key.
  attr_accessor :aws_secret_access_key
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
      digest = Base64.encode64(Digest::MD5.digest(options[:body])).strip
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
