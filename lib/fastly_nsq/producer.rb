require 'forwardable'

module FastlyNsq
  class Producer
    extend Forwardable
    def_delegator :connection, :terminate
    def_delegator :connection, :write

    def initialize(topic:, ssl_context: nil, connector: nil)
      @topic       = topic
      @tls_options = TlsOptions.as_hash(ssl_context)
      @connector   = connector
    end

    private

    attr_reader :topic, :tls_options

    def connection
      @connection ||= connector.new(params)
    end

    def connector
      @connector || FastlyNsq.strategy::Producer
    end

    def params
      {
        nsqd:        ENV.fetch('NSQD_TCP_ADDRESS'),
        topic:       topic,
      }.merge(tls_options)
    end
  end
end
