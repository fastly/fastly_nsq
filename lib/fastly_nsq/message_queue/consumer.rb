class InvalidParameterError < StandardError; end

module MessageQueue
  class Consumer
    def initialize(topic:, channel:)
      @topic = topic
      @channel = channel
    end

    def connection
      @connection ||= consumer.new(params)
    end

    def terminate
      @connection.terminate
    end

    private

    attr_reader :channel, :topic

    def consumer
      Strategy.for_queue::Consumer
    end

    def params
      {
        nsqlookupd: ENV.fetch('NSQLOOKUPD_HTTP_ADDRESS'),
        topic: topic,
        channel: channel,
      }
    end
  end
end
