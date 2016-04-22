class InvalidParameterError < StandardError; end

module MessageQueue
  class Consumer
    def initialize(topic:, channel:, ssl_context: nil)
      @topic = topic
      @channel = channel
      @ssl_context = SSLContext.new(ssl_context)
    end

    def terminate
      connection.terminate
    end

    def connect
      !!connection
    end

    private

    attr_reader :channel, :topic, :ssl_context

    def connection
      @connection ||= consumer.new(params)
    end

    def consumer
      Strategy.for_queue::Consumer
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
