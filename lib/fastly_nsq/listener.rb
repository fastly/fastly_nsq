# frozen_string_literal: true

class FastlyNsq::Listener
  extend Forwardable

  DEFAULT_PRIORITY = 0
  DEFAULT_CONNECTION_TIMEOUT = 5 # seconds

  def_delegators :consumer, :connected?

  attr_reader :preprocessor, :topic, :processor, :priority, :channel, :logger, :consumer

  def initialize(topic:, processor:, preprocessor: FastlyNsq.preprocessor, channel: FastlyNsq.channel, consumer: nil,
                 logger: FastlyNsq.logger, priority: DEFAULT_PRIORITY, connect_timeout: DEFAULT_CONNECTION_TIMEOUT)

    raise ArgumentError, "processor #{processor.inspect} does not respond to #call" unless processor.respond_to?(:call)
    raise ArgumentError, "priority #{priority.inspect} must be a Integer" unless priority.is_a?(Integer)

    @channel      = channel
    @logger       = logger
    @preprocessor = preprocessor
    @processor    = processor
    @topic        = topic
    @priority     = priority

    @consumer = consumer || FastlyNsq::Consumer.new(topic: topic,
                                                    connect_timeout: connect_timeout,
                                                    channel: channel,
                                                    queue: FastlyNsq::Feeder.new(self, priority))

    FastlyNsq.manager.add_listener(self)
  end

  def call(nsq_message)
    message = FastlyNsq::Message.new(nsq_message)
    log message
    preprocessor&.call(message)
    result = processor.call(message)
    nsq_message.finish if result
  end

  def terminate
    return unless connected?
    consumer.terminate
    logger.info "< Consumer terminated: topic [#{topic}]"
  end

  private

  def log(message)
    logger&.info "[NSQ] Message received on topic [#{topic}]: #{message}"
  end
end
