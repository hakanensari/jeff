module Jeff
  # A minimum-viable Amazon Web Services (AWS) client.
  class Client
    include UserAgent

    # Internal: Returns the String request body.
    attr :body

    # Internal: Returns the Proc chunked request body.
    attr :chunker

    # Gets/Sets the String AWS access key id.
    attr_accessor :key

    # Gets/Sets the String AWS secret key.
    attr_accessor :secret

    # Creates a new client.
    #
    # endpoint - A String AWS endpoint.
    #
    # Examples
    #
    #   client = Jeff.new 'http://ecs.amazonaws.com/onca/xml'
    #
    def initialize(endpoint)
      @endpoint   = URI endpoint
      @connection = Excon.new endpoint.to_s, :headers => {
        'User-Agent' => USER_AGENT
      }

      reset_request_attributes
    end

    # Updates the request attributes.
    #
    # data - A Hash of parameters or a String request body or a Proc that will
    #        deliver chunks of data.
    #
    # Returns self.
    #
    # Examples
    #
    #   @client << {
    #     'AssociateTag' => 'tag',
    #     'Service'      => 'AWSECommerceService',
    #     'Version'      => '2011-08-01'
    #   }
    #
    def <<(data)
      case data
      when Hash
        @params.update data
      when String
        @body ||= '' << data
      when Proc
        @chunker = data
      end

      self
    end

    # Configures the client.
    #
    # Yields self.
    #
    # Examples
    #
    #   client.configure do |c|
    #     c.key    = 'key'
    #     c.secret = 'secret'
    #   end
    #
    def configure
      yield self
    end

    # Returns the Hash request parameters, including required defaults.
    def params
      {
        'AWSAccessKeyId'   => @key,
        'SignatureVersion' => '2',
        'SignatureMethod'  => 'HmacSHA256',
        'Timestamp'        => Time.now.utc.iso8601
      }.merge @params
    end

    # Makes an HTTP request.
    #
    # Returns an Excon::Response.
    def request(opts = {}, &blk)
      opts.update :body          => @body,
                  :method        => action,
                  :query         => query,
                  :request_block => @chunker

      begin
        @connection.request opts, &blk
      ensure
        reset_request_attributes
      end
    end

    # Returns the String URL.
    def url
      [@endpoint, query].join '?'
    end

    private

    def action
      @body || @chunker ? :post : :get
    end

    def query
      @query_builder ||= QueryBuilder.new @endpoint, @secret
      @query_builder.build action, params
    end

    def reset_request_attributes
      @body    = nil
      @chunker = nil
      @params  = {}
    end
  end
end
