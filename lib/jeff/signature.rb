module Jeff
  class Signature
    SHA256 = OpenSSL::Digest::SHA256.new

    def initialize(secret, message)
      @secret  = secret
      @message = message
    end

    def digest
      OpenSSL::HMAC.digest SHA256, @secret, @message
    end

    def to_s
      Base64.encode64(digest).chomp
    end
  end
end
