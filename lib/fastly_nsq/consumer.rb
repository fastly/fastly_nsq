require 'forwardable'

module FastlyNsq
  class Consumer
    extend Forwardable
    def_delegator :connection, :pop
    def_delegator :connection, :pop_without_blocking
    def_delegator :connection, :size
    def_delegator :connection, :terminate

    def initialize(topic:, channel:, ssl_context: nil, connector: nil)
      @topic       = topic
      @channel     = channel
      @tls_options = TlsOptions.as_hash(ssl_context)
      @connector   = connector
    end

    private

    attr_reader :channel, :topic, :tls_options

    def connection
      @connection ||= connector.new(params)
    end

    def connector
      @connector || FastlyNsq.strategy::Consumer
    end

    def params
      {
        nsqlookupd: ENV.fetch('NSQLOOKUPD_HTTP_ADDRESS').split(',').map(&:strip),
        topic: topic,
        channel: channel,
      }.merge(tls_options)
    end
  end
end
