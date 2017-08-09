module FastlyNsq::Messenger
  DEFAULT_ORIGIN = 'Unknown'.freeze
  @originating_service = DEFAULT_ORIGIN

  module_function

  def deliver(message:, on_topic:, originating_service: nil)
    payload = {
      data: message,
      meta: {
        originating_service: originating_service || self.originating_service,
      },
    }

    producer_for(topic: on_topic) do |producer|
      producer.write payload.to_json
    end
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
