# frozen_string_literal: true

##
# The main interface to setting up a thread that listens for and
# processes NSQ messages from a given topic/channel.
#
# @example
#   FastlyNsq::Listener.new(
#     topic: topic,
#     channel: channel,
#     processor: ->(m) { puts 'got: '+ m.body }
#   )
class FastlyNsq::Listener
  extend Forwardable

  # Default queue priority used when setting up the consumer queue
  DEFAULT_PRIORITY = 0

  # Default NSQ connection timeout in seconds
  DEFAULT_CONNECTION_TIMEOUT = 5

  # @!method connected?
  #   Delegated to +self.consumer+
  #   @return [FastlyNsq::Consumer#connected?]
  def_delegators :consumer, :connected?

  # @return [String] NSQ Channel
  attr_reader :channel

  # @return [FastlyNsq::Consumer]
  attr_reader :consumer

  # @return [Logger]
  attr_reader :logger

  # @return [Integer] maxium number of times an NSQ message will be attempted
  attr_reader :max_attempts

  # @return [Proc]
  attr_reader :preprocessor

  # @return [String] NSQ Topic
  attr_reader :topic

  # @return [Integer] Queue priority
  attr_reader :priority

  # @return [Proc] processor that is called for each message
  attr_reader :processor

  ##
  # Create a FastlyNsq::Listener
  #
  # @param topic [String] NSQ topic on which to listen
  # @param processor [Proc#call] Any object that responds to +call+. Each message will
  #   be processed with +processor.call(FastlyNsq::Message.new(nsq_message))+.
  #   The processor should return +true+ to indicate that processing is complete
  #   and NSQ message can be finished. The processor is passed an instance of {FastlyNsq::Message}
  #   so the provided Proc can optionally manage the message state using methods provided by {FastlyNsq::Message}.
  # @param preprocessor [Proc#call] Any object that responds to +call+. Similar to the processor
  #   each message it processes via +preprocessor.call(message)+. Default: {FastlyNsq.preprocessor}
  # @param channel [String] NSQ Channel on which to listen. Default: {FastlyNsq.channel}
  # @param consumer [FastlyNsq::Consumer] interface to read messages off the queue. If value is +nil+ the
  #   constructor will create a {FastlyNsq::Consumer} based on the provided parameters.
  # @param logger [Logger] Default: {FastlyNsq.logger}
  # @param priority [Integer] Queue piority. Default: {DEFAULT_PRIORITY}
  # @param connect_timeout [Integer] NSQ connection timeout in seconds. Default: {DEFAULT_CONNECTION_TIMEOUT}
  # @param max_attempts [Integer] maximum number of times an NSQ message will be attemped Default: {FastlyNsq.max_attempts}
  #   When set to +nil+, attempts will be unlimited
  # @param consumer_options [Hash] additional options forwarded to the {FastlyNsq::Consumer}} contructor
  #
  # @example
  #   FastlyNsq::Listener.new(
  #     topic: topic,
  #     channel: channel,
  #     processor: MessageProcessor,
  #     max_attempts: 15,
  #   )
  def initialize(topic:, processor:, preprocessor: FastlyNsq.preprocessor, channel: FastlyNsq.channel, consumer: nil,
                 logger: FastlyNsq.logger, priority: DEFAULT_PRIORITY, connect_timeout: DEFAULT_CONNECTION_TIMEOUT,
                 max_attempts: FastlyNsq.max_attempts, **consumer_options)

    raise ArgumentError, "processor #{processor.inspect} does not respond to #call" unless processor.respond_to?(:call)
    raise ArgumentError, "priority #{priority.inspect} must be a Integer" unless priority.is_a?(Integer)

    @channel      = channel
    @logger       = logger
    @max_attempts = max_attempts
    @preprocessor = preprocessor
    @priority     = priority
    @processor    = processor
    @topic        = topic

    @consumer = consumer || FastlyNsq::Consumer.new(topic: topic,
                                                    connect_timeout: connect_timeout,
                                                    channel: channel,
                                                    queue: FastlyNsq::Feeder.new(self, priority),
                                                    max_attempts: max_attempts,
                                                    **consumer_options)

    FastlyNsq.manager.add_listener(self)
  end

  ##
  # Process an NSQ message.
  #
  # @see FastlyNsq::Feeder#push
  #
  # @param nsq_message [Nsq::Message]
  #   @see {https://www.rubydoc.info/gems/nsq-ruby/Nsq/Message}
  #
  # @return [FastlyNsq::Message]
  def call(nsq_message)
    message = FastlyNsq::Message.new(nsq_message)

    msg_info = {
      channel:  channel,
      topic:    topic,
      attempts: nsq_message.attempts,
      id:       Digest::MD5.hexdigest(nsq_message.body.to_s),
      metadata: message.meta,
    }

    logger.info do
      if logger.level == Logger::DEBUG
        msg_info.merge(data: message.body)
      else
        msg_info
      end
    end

    class_name = processor.is_a?(Class) ? processor.name : processor.class.name

    FastlyNsq.tracer.trace_with_newrelic(params: msg_info, class_name: class_name) do
      preprocessor&.call(message)
      result = processor.call(message)
      message.finish if result
    end

    message
  end

  ##
  # Close the NSQ Conneciton
  #
  # @see FastlyNsq::Consumer#terminate
  def terminate
    return unless connected?
    consumer.terminate
    logger.info "topic #{topic}, channel #{channel}: consumer terminated"
  end
end
