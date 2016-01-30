class MessageQueue
  CHANNEL = 'billing_app'.freeze

  def initialize(topic:)
    @topic = topic
  end

  def producer
    @producer ||= queue.producer(topic: topic)
  end

  def consumer
    @consumer ||= queue.consumer(topic: topic, channel: CHANNEL)
  end

  def queue
    if ENV['FAKE_QUEUE'].nil?
      NsqMessageQueue
    else
      FakeMessageQueue
    end
  end

  private

  attr_reader :topic
end
