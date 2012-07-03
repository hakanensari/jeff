module Jeff
  class QueryBuilder
    UNRESERVED = /([^\w.~-]+)/

    def initialize(endpoint, secret)
      @endpoint = endpoint
      @secret   = secret
    end

    def build(mth, params)
      @mth   = mth.to_s.upcase
      @query = stringify params

      "#{@query}&Signature=#{escape signature}"
    end

    private

    def escape(val)
      val.to_s.gsub(UNRESERVED) do
        '%' + $1.unpack('H2' * $1.bytesize).join('%').upcase
      end
    end

    def signature
      Signature.new @secret, string_to_sign
    end

    def string_to_sign
      [
        @mth,
        @endpoint.host,
        @endpoint.path,
        @query
      ].join "\n"
    end

    def stringify(hsh)
      hsh.map { |k, v| "#{k}=#{ escape v }" }.sort.join '&'
    end
  end
end
