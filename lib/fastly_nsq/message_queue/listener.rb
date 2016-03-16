module MessageQueue
  class Listener
    def initialize(topic:, channel:)
      @topic = topic
      @channel = channel
    end

    def go
      Signal.trap('INT') do
        shutdown
      end

      Signal.trap('TERM') do
        shutdown
      end

      loop do
        process_one_message
      end
    end

    def process_next_message
      process_one_message
      consumer.terminate
    end

    private

    attr_reader :channel, :topic

    def process_one_message
      message = consumer.pop
      MessageProcessor.new(message_body: message.body, topic: topic).go
      message.finish
    end

    def consumer
      @consumer ||= MessageQueue::Consumer.new(consumer_params).connection
    end

    def consumer_params
      { topic: topic, channel: channel }
    end

    def shutdown
      consumer.terminate
      exit
    end
  end
end
