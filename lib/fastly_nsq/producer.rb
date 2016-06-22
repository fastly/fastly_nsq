require 'forwardable'

module FastlyNsq
  class Producer
    extend Forwardable
    def_delegator :connection, :terminate
    def_delegator :connection, :write

    def initialize(topic:, ssl_context: nil, connector: nil)
      @topic       = topic
      @ssl_context = SSLContext.new(ssl_context)
      @connector   = connector
    end

    private

    attr_reader :topic, :ssl_context

    def connection
      @connection ||= connector.new(params)
    end

    def connector
      @connector || FastlyNsq.strategy::Producer
    end

    def params
      {
        nsqd:        ENV.fetch('NSQD_TCP_ADDRESS'),
        topic:       topic,
        ssl_context: ssl_context.to_h,
      }
    end
  end
end
