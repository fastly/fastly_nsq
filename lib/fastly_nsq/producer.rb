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
    @connection ||= Nsq::Producer.new(
      tls_options.merge(
        nsqlookupd:  FastlyNsq.lookupd_http_addresses,
        topic:       topic,
      ),
    )

    Timeout.timeout(connect_timeout) { sleep(0.1) until connection.connected? }

    true
  rescue Timeout::Error => error
    logger.error { "Producer for #{topic} failed to connect!" }
    terminate
    raise error
  end

  private

  attr_reader :tls_options
end
