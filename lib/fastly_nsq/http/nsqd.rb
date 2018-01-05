# frozen_string_literal: true

require 'fastly_nsq/http'

class FastlyNsq::Http
  class Nsqd
    extend Forwardable
    def_delegator :client, :get
    def_delegator :client, :post

    BASE_NSQD_URL = ENV.fetch('NSQD_URL') do
      if ENV['NSQD_HTTPS_ADDRESS']
        "https://#{ENV.fetch('NSQD_HTTPS_ADDRESS')}"
      else
        "http://#{ENV.fetch('NSQD_HTTP_ADDRESS')}"
      end
    end
    VALID_FORMATS = %w[text json].freeze

    ##
    # Monitoring endpoint, should return 200 OK. It returns an HTTP 500 if it is not healthy.
    #
    # NOTE: The only "unhealthy" state is if nsqd failed to write messages to disk when overflow occurred.
    def self.ping(**args)
      new(request_uri: '/ping', **args).get
    end

    ##
    # NSQ version information
    def self.info(**args)
      new(request_uri: '/info', **args).get
    end

    ##
    # Return Internal Statistics
    #
    # @param topic [String] filter to topic
    # @param channel [String] filter to channel
    # @param format [String] can be +text+ or +json+
    #
    # @raise [InvaildFormatError] provided format is not in list of valid formats
    #
    # @example Fetch Statistics for topic: 'foo', channel: 'bar' as text
    #   Nsqd.stats(topic: 'foo', channel: 'bar', format: 'text')
    def self.stats(topic: nil, channel: nil, format: 'json', **args)
      raise InvalidFormatError unless VALID_FORMATS.include?(format)
      params = { format: format }
      params[:topic] = topic if topic
      params[:channel] = channel if channel
      new(request_uri: '/stats', **args).get(params)
    end

    ##
    # Publish a message
    #
    # @param topic [String] the topic to publish to
    # @param defer [String] the time in ms to delay message delivery
    # @param message the message body
    def self.pub(topic:, message:, defer: nil, **args)
      params = { topic: topic }
      params[:defer] = defer if defer
      new(request_uri: '/pub', **args).post(params, message)
    end

    ##
    # Publish multiple messages in one roundtrip
    #
    # NOTE: by default +/mpub+ expects messages to be delimited by +\n+, use the
    #       +binary: true+ parameter to enable binary mode where message body
    #       is expected to be in the following format (the HTTP Content-Length
    #       header should be sent as the total size of the POST body):
    #          [ 4-byte num messages ]
    #          [ 4-byte message #1 size ][ N-byte binary data ]
    #              ... (repeated <num_messages> times)
    #
    # TODO: setup +Content-Legth+ header when binary is passed.
    #
    # @param topic [String] the topic to publish to
    # @param binary [Boolean] enables binary mode
    # @param message the messages to send with \n used to seperate messages
    def self.mpub(topic:, binary: false, message:, **args)
      binary_param = binary ? 'true' : 'false'
      raise NotImplementedError, 'binary mode has yet to be implemented' if binary
      params = { topic: topic, binary: binary_param }
      new(request_uri: '/mpub', **args).post(params, message)
    end

    ##
    # List of nsqlookupd TCP addresses
    def self.config_nsqlookupd_tcp_addresses(**args)
      new(request_uri: '/config/nsqlookupd_tcp_addresses', **args).get
    end

    ##
    # Create a topic
    #
    # @param topic [String] the topic to create
    def self.topic_create(topic:, **args)
      new(request_uri: '/topic/create', **args).post(topic: topic)
    end

    ##
    # Delete a topic (and all of its channels)
    #
    # @param topic [String] the existing topic to delete
    def self.topic_delete(topic:, **args)
      new(request_uri: '/topic/delete', **args).post(topic: topic)
    end

    ##
    # Empty all the queued messages (in-memory and disk) for an existing topic
    #
    # @param topic [String] the existing topic to empty
    def self.topic_empty(topic:, **args)
      new(request_uri: '/topic/empty', **args).post(topic: topic)
    end

    ##
    # Pause message flow to all channels on an existing topic
    # (messages will queue at the *topic*)
    #
    # @param topic [String] the existing topic to pause
    def self.topic_pause(topic:, **args)
      new(request_uri: '/topic/pause', **args).post(topic: topic)
    end

    ##
    # Unpause message flow to all channels of an existing, paused, topic
    #
    # @param topic [String] the existing, paused topic to unpause
    def self.topic_unpause(topic:, **args)
      new(request_uri: '/topic/unpause', **args).post(topic: topic)
    end

    ##
    # Create a channel for an existing topic
    #
    # @param topic [String] the existing topic
    # @param channel [String] the channel to create
    def self.channel_create(topic:, channel:, **args)
      new(request_uri: '/channel/create', **args).post(topic: topic, channel: channel)
    end

    ##
    # Delete an existing channel for an existing topic
    #
    # @param topic [String] the existing topic
    # @param channel [String] the channel to delete
    def self.channel_delete(topic:, channel:, **args)
      new(request_uri: '/channel/delete', **args).post(topic: topic, channel: channel)
    end

    ##
    # Empty all queued messages (in-memory and disk) for an existing channel
    #
    # @param topic [String] the existing topic
    # @param channel [String] the channel to empty
    def self.channel_empty(topic:, channel:, **args)
      new(request_uri: '/channel/empty', **args).post(topic: topic, channel: channel)
    end

    ##
    # Pause message flow to consumers of an existing channel
    # (messages will queue at the *channel*)
    #
    # @param topic [String] the existing topic
    # @param channel [String] the channel to pause
    def self.channel_pause(topic:, channel:, **args)
      new(request_uri: '/channel/pause', **args).post(topic: topic, channel: channel)
    end

    ##
    # Resume message flow to consumers of and existing, paused, channel
    #
    # @param topic [String] the existing topic
    # @param channel [String] the existing, paused, channel to unpause
    def self.channel_unpause(topic:, channel:, **args)
      new(request_uri: '/channel/unpause', **args).post(topic: topic, channel: channel)
    end

    ##
    # Nsqd http wrapper. Provides a simple interface to all NSQD http api's
    # @see http://nsq.io/components/nsqd.html
    #
    # @attr [String] request_uri the request you would like to call ie: '/thing'
    # @attr [String] base_uri the host, port, and protocol of your nsqd
    # @attr [Object] adapter the http adapter you would like to use...
    def initialize(request_uri:, base_uri: BASE_NSQD_URL, adapter: FastlyNsq::Http)
      @base_uri = base_uri
      @adapter = adapter
      uri = URI.join(@base_uri, request_uri)

      @client = @adapter.new(uri: uri)
      @client.use_ssl
    end

    private

    attr_accessor :client

    class InvalidFormatError < StandardError; end
  end
end
