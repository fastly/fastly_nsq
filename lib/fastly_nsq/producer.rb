# frozen_string_literal: true

class FastlyNsq::Producer
  DEFAULT_CONNECTION_TIMEOUT = 5 # seconds

  attr_reader :topic, :connect_timeout, :connection, :logger

  def initialize(topic:, tls_options: nil, logger: FastlyNsq.logger, connect_timeout: DEFAULT_CONNECTION_TIMEOUT)
    @topic           = topic
    @tls_options     = FastlyNsq::TlsOptions.as_hash(tls_options)
    @connect_timeout = connect_timeout
    @logger          = logger

    connect
  end

  def terminate
    connection.terminate
    @connection = nil
  end

  def connected?
    return false unless connection

    connection.connected?
  end

  def write(message)
    raise FastlyNsq::NotConnectedError unless connected?
    connection.write message
  end

  def connect
    lookupd = FastlyNsq.lookupd_http_addresses

    @connection ||= Nsq::Producer.new(
      tls_options.merge(
        nsqlookupd:  lookupd,
        topic:       topic,
      ),
    )

    timeout_args = [connect_timeout, FastlyNsq::ConnectionFailed]

    if RUBY_VERSION > '2.4.0'
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
