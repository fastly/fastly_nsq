# frozen_string_literal: true

class FastlyNsq::Producer
  DEFAULT_CONNECTION_TIMEOUT = 5 # seconds

  attr_reader :topic, :connect_timeout, :connection

  def initialize(topic:, tls_options: nil, connect_timeout: DEFAULT_CONNECTION_TIMEOUT)
    @topic           = topic
    @tls_options     = FastlyNsq::TlsOptions.as_hash(tls_options)
    @connect_timeout = connect_timeout

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
    FastlyNsq.logger.error "Producer for #{topic} failed to connect!"
    connection.terminate
    raise error
  end

  private

  attr_reader :tls_options
end
