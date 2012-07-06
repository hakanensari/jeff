require 'base64'

module Jeff
  class Secret
    SHA256 = OpenSSL::Digest::SHA256.new

    def initialize(key)
      @key = key
    end

    def sign(message)
      Base64.encode64(digest(message)).chomp
    end

    private

    def digest(message)
      OpenSSL::HMAC.digest SHA256, @key, message
    end
  end
end
