require 'forwardable'

module FastlyNsq
  class Consumer
    extend Forwardable
    def_delegator :connection, :pop
    def_delegator :connection, :pop_without_blocking
    def_delegator :connection, :size
    def_delegator :connection, :terminate

    def initialize(topic:, channel:, ssl_context: nil, connector: nil)
      @topic       = topic
      @channel     = channel
      @ssl_context = SSLContext.new(ssl_context)
      @connector   = connector
    end

    private

    attr_reader :channel, :topic, :ssl_context

    def connection
      @connection ||= connector.new(params)
    end

    def connector
      @connector || FastlyNsq.strategy::Consumer
    end

    def params
      {
        nsqlookupd: ENV.fetch('NSQLOOKUPD_HTTP_ADDRESS'),
        topic: topic,
        channel: channel,
        ssl_context: ssl_context.to_h,
      }
    end
  end
end
