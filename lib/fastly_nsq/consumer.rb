# frozen_string_literal: true

# Provides an adapter to an Nsq::Consumer
# and used to read messages off the queue.
#
# @example
#   consumer = FastlyNsq::Consumer.new(
#     topic: 'topic',
#     channel: 'channel'
#   )
#   consumer.size #=> 1
#   message = consumer.pop
#   message.body #=> "{ 'data': { 'key': 'value' } }"
#   message.finish
#   consumer.size #=> 0
#   consumer.terminate

class FastlyNsq::Consumer
  extend Forwardable

  # Default NSQ connection timeout in seconds
  DEFAULT_CONNECTION_TIMEOUT = 5

  # @return [String] NSQ Channel
  attr_reader :channel

  # @return [String] NSQ Topic
  attr_reader :topic

  # @return [Nsq::Consumer]
  attr_reader :connection

  # @return [Integer] connection timeout in seconds
  attr_reader :connect_timeout

  # @return [Integer] maximum number of times an NSQ message will be attempted
  attr_reader :max_attempts

  # @!method connected?
  #   Delegated to +self.connection+
  #   @return [Nsq::Consumer#connected?]
  #   @see https://www.rubydoc.info/gems/nsq-ruby/Nsq/ClientBase#connected%3F-instance_method Nsq::ClientBase#connected?
  # @!method pop
  #   Delegated to +self.connection+
  #   @return [Nsq::Consumer#pop]
  #   @see https://www.rubydoc.info/gems/nsq-ruby/Nsq%2FConsumer:pop Nsq::Consumer#pop
  # @!method pop_without_blocking
  #   Delegated to +self.connection+
  #   @return [Nsq::Consumer#pop_without_blocking]
  #   @see https://www.rubydoc.info/gems/nsq-ruby/Nsq%2FConsumer:pop_without_blocking Nsq::Consumer#pop_without_blocking
  # @!method size
  #   Delegated to +self.connection+
  #   @return [Nsq::Consumer#size]
  #   @see https://www.rubydoc.info/gems/nsq-ruby/Nsq%2FConsumer:size Nsq::Consumer#size
  # @!method terminate
  #   Delegated to +self.connection+
  #   @return [Nsq::Consumer#terminate]
  #   @see https://www.rubydoc.info/gems/nsq-ruby/Nsq%2FClientBase:terminate Nsq::ClientBase#terminate
  def_delegators :connection, :connected?, :pop, :pop_without_blocking, :size, :terminate

  ##
  # Create a FastlyNsq::Consumer
  #
  # @param topic [String] NSQ topic from which to consume
  # @param channel [String] NSQ channel from which to consume
  # @param queue [#pop, #size] Queue object, most likely an instance of {FastlyNsq::Feeder}
  # @param tls_options [Hash] Hash of TSL options passed the connection.
  #   In most cases this should be nil unless you need to override the
  #   default values set in ENV.
  # @param connect_timeout [Integer] NSQ connection timeout in seconds
  # @param max_attempts [Integer] maximum number of times an NSQ message will be attemped
  #   When set to +nil+, attempts will be unlimited
  # @param options [Hash] addtional options forwarded to the connection contructor
  #
  # @example
  #   consumer = FastlyNsq::Consumer.new(
  #     topic: 'topic',
  #     channel: 'channel'
  #   )
  def initialize(topic:, channel:, queue: nil, tls_options: nil, connect_timeout: DEFAULT_CONNECTION_TIMEOUT, max_attempts: FastlyNsq.max_attempts, **options)
    @topic           = topic
    @channel         = channel
    @tls_options     = FastlyNsq::TlsOptions.as_hash(tls_options)
    @connect_timeout = connect_timeout
    @max_attempts    = max_attempts

    @connection = connect(queue, **options)
  end

  ##
  # Is the message queue empty?
  # @return [Boolean]
  def empty?
    size.zero?
  end

  private

  attr_reader :tls_options

  def connect(queue, **options)
    Nsq::Consumer.new(
      {
        nsqlookupd: FastlyNsq.lookupd_http_addresses,
        topic: topic,
        channel: channel,
        queue: queue,
        max_attempts: max_attempts,
        **options,
      }.merge(tls_options),
    )
  end
end
