require 'base64'
require 'openssl'

module Jeff
  class Secret
    SHA256 = OpenSSL::Digest::SHA256.new

    def initialize(key)
      @key = key
    end

    def sign(message)
      digest = OpenSSL::HMAC.digest(SHA256, @key, message)
      Base64.encode64(digest).chomp
    end
  end
end
