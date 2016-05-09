require 'forwardable'

class InvalidParameterError < StandardError; end

module MessageQueue
  class Producer
    extend Forwardable
    def_delegator :connection, :terminate
    def_delegator :connection, :write

    def initialize(topic:, ssl_context: nil)
      @topic = topic
      @ssl_context = SSLContext.new(ssl_context)
    end

    private

    attr_reader :topic, :ssl_context

    def connection
      Strategy.for_queue::Producer.new params
    end

    def params
      {
        nsqd: ENV.fetch('NSQD_TCP_ADDRESS'),
        topic: topic,
        ssl_context: ssl_context.to_h,
      }
    end
  end
end
