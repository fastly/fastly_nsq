# frozen_string_literal: true

##
# Provides interface for writing messages to NSQ.
# Manages tracking and creation of {FastlyNsq::Producer}s
# @example
#   FastlyNsq::Messenger.deliver(
#     message: message,
#     topic: 'topic',
#     meta: metadata_hash,
#   )
module FastlyNsq::Messenger
  DEFAULT_ORIGIN = 'Unknown'
  @originating_service = DEFAULT_ORIGIN

  module_function

  ##
  # Deliver an NSQ message
  # @param message [#to_s] written to the +data+ key of the NSQ message payload
  # @param topic [String] NSQ topic on which to deliver the message
  # @param originating_service [String] added to meta key of message payload
  # @param meta [Hash]
  # @return [Void]
  def deliver(message:, topic:, originating_service: nil, meta: {})
    payload = {
      data: message,
      meta: populate_meta(originating_service: originating_service, meta: meta),
    }

    deliver_payload(topic: topic, payload: payload.to_json)
  end

  def originating_service=(service)
    @originating_service = service
  end

  ##
  # @param topic [String] NSQ topic
  # @return [FastlyNsq::Producer] returns producer for given topic
  def producer_for(topic:)
    producer = producers[topic]

    yield producer if block_given?

    producer
  end

  ##
  # Map of subscribed topics to FastlyNsq::Producer
  # @return [Hash]
  def producers
    @producers ||= Hash.new { |hash, topic| hash[topic] = FastlyNsq::Producer.new(topic: topic) }
  end

  ##
  # Terminate producer for given topic
  # @param topic [String] NSQ topic
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

  private_class_method

  def deliver_payload(topic:, payload:)
    producer_for(topic: topic) { |producer| producer.write payload }
  end

  def populate_meta(originating_service: nil, meta: {})
    meta[:originating_service] = originating_service || self.originating_service
    meta[:sent_at] = Time.now.iso8601(5)
    meta
  end
end
