# frozen_string_literal: true

module FastlyNsq::Messenger
  DEFAULT_ORIGIN = 'Unknown'
  @originating_service = DEFAULT_ORIGIN

  module_function

  def deliver(message:, topic:, originating_service: nil, meta: {})
    meta[:originating_service] = originating_service || self.originating_service
    meta[:sent_at] = Time.now.iso8601(5)

    payload = {
      data: message,
      meta: meta,
    }

    producer_for(topic: topic) { |producer| producer.write payload.to_json }
  end

  def originating_service=(service)
    @originating_service = service
  end

  def producer_for(topic:)
    producer = producers[topic]

    yield producer if block_given?

    producer
  end

  def producers
    @producers ||= Hash.new { |hash, topic| hash[topic] = FastlyNsq::Producer.new(topic: topic) }
  end

  def terminate_producer(topic:)
    producer_for(topic: topic).terminate
    producers.delete(topic)
  end

  def terminate_all_producers
    producers.each do |topic, producer|
      producer.terminate
      producers.delete(topic)
    end
  end

  def originating_service
    @originating_service || DEFAULT_ORIGIN
  end
end
