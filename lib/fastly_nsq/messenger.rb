
class FastlyNsq::Messenger
  def initialize(originating_service:, producer: nil)
    @originating_service = originating_service
    @producer = producer
  end

  def deliver(message:, on_topic:)
    payload = {
      data: message,
      meta: {
        originating_service: originating_service,
      },
    }

    queue = nil
    producer_for(topic: on_topic) do |producer|
      queue = producer.write payload.to_json
    end

  ensure
    queue.close if queue
  end

  private

  attr_reader :originating_service

  def producer_for(topic:)
    producer = @producer || FastlyNsq::Producer.new(topic: topic)
    yield producer
  ensure
    producer.terminate
  end
end
