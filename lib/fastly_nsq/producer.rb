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
    lookupd = FastlyNsq.lookupd_http_addresses

    @connection ||= Nsq::Producer.new(
      tls_options.merge(
        nsqlookupd: lookupd,
        topic: topic
      )
    )

    timeout_args = [connect_timeout, FastlyNsq::ConnectionFailed]

    if RUBY_VERSION > "2.4.0"
      timeout_args << "Failed connection to #{lookupd} within #{connect_timeout} seconds"
    end

    Timeout.timeout(*timeout_args) { Thread.pass until connection.connected? }

    true
  rescue FastlyNsq::ConnectionFailed
    logger.error { "Producer for #{topic} failed to connect!" }
    terminate
    raise
  end

  private

  attr_reader :tls_options
end
