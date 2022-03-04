# frozen_string_literal: true

# Provides an adapter to an Nsq::Producer
# and used to write messages to the queue.
#
# @example
#   producer = FastlyNsq::Producer.new(topic: 'topic)
#   producer.write('my message')
class FastlyNsq::Producer
  DEFAULT_CONNECTION_TIMEOUT = 5 # seconds

  # @return [String] NSQ Topic
  attr_reader :topic

  # @return [Nsq::Producer]
  attr_reader :connection

  # @return [Integer] connection timeout in seconds
  attr_reader :connect_timeout

  # @return [Logger]
  attr_reader :logger

  ##
  # Create a FastlyNsq::Producer
  #
  # Will connect to NSQDs in this priority: 1. direct from FastlyNsq.producer_nsqds 2. discovered via FastlyNsq.lookupd_http_addresses.
  # If both `producer_nsqds` and `lookupd_http_addresses` are set only the FastlyNsq.producer_nsqds will be used.
  #
  # @param topic [String] NSQ topic on which to deliver the message
  # @param tls_options [Hash] Hash of TSL options passed the connection.
  #   In most cases this should be nil unless you need to override the
  #   default values set in ENV.
  # @param logger [Logger] defaults to FastlyNsq.logger
  # @param connect_timeout [Integer] NSQ connection timeout in seconds
  def initialize(topic:, tls_options: nil, logger: FastlyNsq.logger, connect_timeout: DEFAULT_CONNECTION_TIMEOUT)
    @topic = topic
    @tls_options = FastlyNsq::TlsOptions.as_hash(tls_options)
    @connect_timeout = connect_timeout
    @logger = logger

    connect
  end

  ##
  # Terminate the NSQ connection and set connection instance to +nil+
  # @return [Nsq::Producer#terminate]
  # @see https://www.rubydoc.info/gems/nsq-ruby/Nsq%2FClientBase:terminate Nsq::ClientBase#terminate
  def terminate
    connection.terminate
    @connection = nil
  end

  ##
  # Check conenction status
  # @return [Nsq::Consumer#connected?]
  # @see https://www.rubydoc.info/gems/nsq-ruby/Nsq/ClientBase#connected%3F-instance_method Nsq::ClientBase#connected?
  def connected?
    return false unless connection

    connection.connected?
  end

  ##
  # Write a message
  # @return [Nsq::Producer#pop]
  # @see https://www.rubydoc.info/gems/nsq-ruby/Nsq%2FProducer:write Nsq::Producer#write
  def write(message)
    raise FastlyNsq::NotConnectedError unless connected?
    connection.write(*message)
  end

  ##
  # Create an Nsq::Producer and set as +@connection+ instance variable
  # @return [Boolean]
  def connect
    producers = FastlyNsq.producer_nsqds
    lookupd = FastlyNsq.lookupd_http_addresses

    opts = tls_options.merge(topic: topic)

    if !producers.empty?
      opts[:nsqd] = producers
    elsif !lookupd.empty?
      opts[:nsqlookupd] = lookupd
    else
      raise FastlyNsq::ConnectionFailed, "One of FastlyNsq.producer_nsqds or FastlyNsq.lookupd_http_addresses must be present"
    end

    @connection ||= Nsq::Producer.new(opts)

    timeout_args = [
      connect_timeout,
      FastlyNsq::ConnectionFailed,
      "Failed connection to #{opts[:nsqd] || opts[:nsqlookupd]} within #{connect_timeout} seconds"
    ]

    Timeout.timeout(*timeout_args) { Thread.pass until connection.connected? }

    true
  rescue FastlyNsq::ConnectionFailed
    logger.error { "Producer for #{topic} failed to connect!" }
    terminate if @connection
    raise
  end

  private

  attr_reader :tls_options
end
