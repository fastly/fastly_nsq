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
  # Deliver an NSQ message. Uses +pub+
  #
  # Adds keys to the `+meta+:
  #   +originating_service+ which defaults to {FastlyNsq#originating_service}.
  #   +sent_at+ which will be set to +Time.now.iso8601(5)+ if the +sent_at+ param is nil OR
  #   if the passed +sent_at+ is not a valid timestamp.
  # @param message [#to_json(*)] written to the +data+ key of the NSQ message payload
  # @param topic [String] NSQ topic on which to deliver the message
  # @param originating_service [String] added to meta key of message payload
  # @param sent_at [Time] Timestamp that will be added to the meta payload
  # @param meta [Hash]
  # @return [Void]
  # @example
  #   FastlyNsq::Messenger.deliver(
  #     message: {a: 1, count: 123},
  #     topic: 'count',
  #     meta: { sent_at: Time.now }
  #   )
  def deliver(message:, topic:, originating_service: nil, sent_at: nil, meta: {})
    payload = {
      data: message,
      meta: populate_meta(originating_service: originating_service, sent_at: sent_at, meta: meta),
    }

    deliver_payload(topic: topic, payload: payload.to_json)
  end

  ##
  # Deliver many NSQ messages at once. Uses +mpub+
  #
  # For each message will add two keys to the `+meta+ payload of each message:
  #   +originating_service+ which defaults to {FastlyNsq#originating_service}
  #   +sent_at+ which will be set to +Time.now.iso8601(5)+ when messages are processed if not included
  #   in the +meta+ param OR if the pased +sent_at+ is not a valid timestamp.
  #   The +sent_at+ time and +originating_service+ will be the same for every message.
  # @param messages [Array] Array of message which will be written to +data+ key of the
  #   individual NSQ message payload. Each message needs to respond to +to_json(*)+.
  # @param topic [String] NSQ topic on which to deliver the message
  # @param originating_service [String] added to meta key of message payload
  # @param sent_at [Time] Timestamp that will be added to the meta payload
  # @param meta [Hash]
  # @return [Void]
  # @example
  #   FastlyNsq::Messenger.deliver_multi(
  #     messages: [{a: 1, count: 11}, {a: 2, count: 22}],
  #     topic: 'counts',
  #   )
  def deliver_multi(messages:, topic:, originating_service: nil, sent_at: nil, meta: {})
    meta = populate_meta(originating_service: originating_service, sent_at: sent_at, meta: meta)

    payload = messages.each_with_object([]) do |message, a|
      msg = {
        data: message,
        meta: meta,
      }

      a << msg.to_json
    end

    deliver_payload(topic: topic, payload: payload)
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

  def populate_meta(originating_service: nil, sent_at: nil, meta: {})
    meta[:originating_service] = originating_service || self.originating_service

    meta[:sent_at] = if sent_at && sent_at.respond_to?(:iso8601)
                       sent_at.iso8601(5)
                     else
                       Time.now.iso8601(5)
                     end

    meta
  end
end
