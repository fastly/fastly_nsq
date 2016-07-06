module MessageQueue
  class Listener
    def initialize(topic:, channel:, processor: nil, consumer: nil)
      @topic     = topic
      @channel   = channel
      @processor = processor || DEFAULT_PROCESSOR
      @consumer  = consumer  || MessageQueue::Consumer.new(consumer_params)
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

    attr_reader :channel, :topic, :processor, :consumer
    DEFAULT_PROCESSOR = ->(body, topic) { ::MessageProcessor.new(message_body: body, topic: topic).go }

    def process_one_message
      message = consumer.pop
      processor.call(message.body, topic)
      message.finish
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
