require 'forwardable'

module Jeff
  class Response
    extend Forwardable

    attr :body

    def_delegators :@body, :eof?, :readpartial

    def_delegators :@chunks, :<<, :close

    def initialize
      @mutex = Mutex.new
      @body, @chunks = IO.pipe
    end

    def status
      Thread.pass while @status.nil?
      @status
    end

    def status=(code)
      @mutex.synchronize { @status = code }
    end
  end
end
