# frozen_string_literal: true

class FastlyNsq::Consumer
  extend Forwardable

  DEFAULT_CONNECTION_TIMEOUT = 5 # seconds

  attr_reader :channel, :topic, :connection, :connect_timeout

  def_delegators :connection, :size, :terminate, :connected?, :pop, :pop_without_blocking

  def initialize(topic:, channel:, queue: nil, tls_options: nil, connect_timeout: DEFAULT_CONNECTION_TIMEOUT, **options)
    @topic           = topic
    @channel         = channel
    @tls_options     = FastlyNsq::TlsOptions.as_hash(tls_options)
    @connect_timeout = connect_timeout

    @connection = connect(queue, **options)
  end

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
        **options,
      }.merge(tls_options),
    )
  end
end
