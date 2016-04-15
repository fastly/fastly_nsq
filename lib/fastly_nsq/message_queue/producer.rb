class InvalidParameterError < StandardError; end

module MessageQueue
  class Producer
    def initialize(topic:, ssl_context: nil)
      @topic = topic
      @ssl_context = SSLContext.new(ssl_context)
    end

    def connection
      @producer ||= producer.new(params)
    end

    def terminate
      @producer.terminate
    end

    private

    attr_reader :topic, :ssl_context

    def producer
      Strategy.for_queue::Producer
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
