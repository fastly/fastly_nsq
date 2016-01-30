require 'active_support/core_ext/object/blank'

class QueueListener
  def initialize(topic:)
    @queue = MessageQueue.new(topic: topic)
  end

  def start
    loop do
      process_next_message
    end
  end

  def process_next_message
    message = consumer.pop

    if message.present?
      MessageProcessor.new(message).start
    end
  end

  def consumer
    queue.consumer
  end

  private

  attr_reader :queue
end
