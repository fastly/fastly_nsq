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

    def process_one_message
      message = consumer.pop
      MessageProcessor.new(message.body).go
      message.finish
    rescue NoMethodError => exception
      if exception.message =~ /method \`body/
        raise EmptyFakeQueueError.new
      else
        raise exception
      end
    end

    attr_reader :channel, :topic

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

class EmptyFakeQueueError < StandardError
  def initialize(message=default_message)
    super
  end

  private

  def default_message
    'You are using the fake queue with no messages and trying to get messages.'
  end
end
