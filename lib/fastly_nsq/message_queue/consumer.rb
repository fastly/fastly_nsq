require 'forwardable'

class InvalidParameterError < StandardError; end

module MessageQueue
  class Consumer
    extend Forwardable
    def_delegator :connection, :pop
    def_delegator :connection, :pop_without_blocking
    def_delegator :connection, :terminate

    def initialize(topic:, channel:, ssl_context: nil)
      @topic = topic
      @channel = channel
      @ssl_context = SSLContext.new(ssl_context)
    end

    private

    attr_reader :channel, :topic, :ssl_context

    def connection
      Strategy.for_queue::Consumer.new(params)
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
