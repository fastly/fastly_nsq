require 'forwardable'

class InvalidParameterError < StandardError; end

module MessageQueue
  class Consumer
    extend Forwardable
    def_delegator :connection, :pop
    def_delegator :connection, :pop_without_blocking
    def_delegator :connection, :size
    def_delegator :connection, :terminate

    def initialize(topic:, channel:, ssl_context: nil, &connector)
      @topic = topic
      @channel = channel
      @ssl_context = SSLContext.new(ssl_context)
      @connector = connector || DEFAULT_CONNECTOR
    end

    private

    attr_reader :channel, :connector, :topic, :ssl_context

    DEFAULT_CONNECTOR = ->(params)  { Strategy.for_queue::Consumer.new(params) }

    def connection
      @connection ||= connector.call(params)
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
