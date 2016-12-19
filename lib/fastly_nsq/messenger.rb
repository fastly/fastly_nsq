module FastlyNsq::Messenger
  def self.deliver(message:, on_topic:, originating_service:)
    payload = {
      data: message,
      meta: {
        originating_service: originating_service,
      },
    }

    producer_for(topic: on_topic) do |producer|
      producer.write payload.to_json
    end
  end
  def self.producer_for(topic:)
    producer = producers[topic]

    yield producer if block_given?

    producer
  end

  def self.producers
    @producers ||= Hash.new { |hash, topic| hash[topic] = FastlyNsq::Producer.new(topic: topic) }
  end

  def self.terminate_producer(topic:)
    producer_for(topic: topic).terminate
    producers.delete(topic)
  end

  def self.terminate_all_producers
    producers.each do |topic, producer|
      producer.terminate
      producers.delete(topic)
    end
  end
end
