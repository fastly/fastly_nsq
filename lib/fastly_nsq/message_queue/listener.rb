module MessageQueue
  class Listener
    def initialize(topic:, channel:)
      @topic = topic
      @channel = channel
    end

    def go
      loop do
        process_next_message
      end
    end

    def process_next_message
      message = consumer.pop
      MessageProcessor.new(message).go
    end

    private

    attr_reader :channel, :topic

    def consumer
      MessageQueue::Consumer.new(topic: topic, channel: channel).connection
    end
  end
end
