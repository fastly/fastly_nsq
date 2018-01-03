# frozen_string_literal: true

class FastlyNsq::Listener
  DEFAULT_PRIORITY = 0
  DEFAULT_CONNECTION_TIMEOUT = 5 # seconds

  attr_reader :preprocessor, :topic, :processor, :priority, :channel

  def initialize(topic:, processor:, preprocessor: nil, channel: nil, consumer: nil, logger: FastlyNsq.logger,
                 priority: DEFAULT_PRIORITY, connect_timeout: DEFAULT_CONNECTION_TIMEOUT)

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

  def connected?
    consumer.connected?
  end

  def terminate
    return unless connected?
    consumer.terminate
    logger.info "< Consumer terminated: topic [#{topic}]"
  end

  private

  attr_reader :logger, :consumer

  def log(message)
    logger&.info "[NSQ] Message received on topic [#{topic}]: #{message}"
  end
end
