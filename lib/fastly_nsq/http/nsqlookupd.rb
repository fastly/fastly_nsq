# frozen_string_literal: true

require 'fastly_nsq/http'

class FastlyNsq::Http::Nsqlookupd
  extend Forwardable
  def_delegator :client, :get

  BASE_NSQLOOKUPD_URL = "http://#{ENV.fetch('NSQLOOKUPD_HTTP_ADDRESS', '').split(',')[0]}"

  ##
  # List of producers for a given topic
  #
  # @param topic [String] the topic for which to list producers
  def self.lookup(topic:)
    new(request_uri: '/lookup').get(topic: topic)
  end

  ##
  # List of all known topics
  def self.topics
    new(request_uri: '/topics').get
  end

  ##
  # List of channels for a given topic
  #
  # @param topic [String] the topic for which to list channels
  def self.channels(topic:)
    new(request_uri: '/channels').get(topic: topic)
  end

  ##
  # List all known nsqd nodes
  def self.nodes
    new(request_uri: '/nodes').get
  end

  ##
  # Deletes an existing topic
  #
  # @param topic [String] the exsiting topic to delete
  def self.delete_topic(topic:)
    new(request_uri: '/delete_topic').get(topic: topic)
  end

  ##
  # Deletes an existing channel of an existing topic
  #
  # @param topic [String] an exsiting topic
  # @param channel [String] the exsiting channel to delete
  def self.delete_channel(topic:, channel:)
    new(request_uri: '/delete_channel').get(topic: topic, channel: channel)
  end

  ##
  # Tombstones a specific producer of an existing topic
  #
  # @see http://nsq.io/components/nsqlookupd.html#deletion_tombstones
  #
  # @param topic [String] the existing topic
  # @param node [String] the producer (nsqd) to tombstone (identified by <broadcast_address>:<http_port>)
  def self.tombstone_topic_producer(topic:, node:)
    # node identified by <broadcast_address>:<http_port>
    new(request_uri: '/tombstone_topic_producer').get(topic: topic, node: node)
  end

  ##
  # Monitoring endpoint, should return +OK+
  def self.ping
    new(request_uri: '/ping').get
  end

  ##
  # Returns nsqlookupd version information
  def self.info
    new(request_uri: '/info').get
  end

  ##
  # Nsqlookupd http wrapper. Provides a simple interface to all NSQlookupd http api's
  # @see http://nsq.io/components/nsqlookupd.html
  #
  # @attr [String] request_uri the request you would like to call ie: '/thing'
  # @attr [String] base_uri the host, port, and protocol of your nsqd
  # @attr [Object] adapter the http adapter you would like to use...
  def initialize(request_uri:, base_uri: nil, adapter: nil)
    @adapter = adapter || FastlyNsq::Http
    @base_uri = base_uri || BASE_NSQLOOKUPD_URL
    uri = URI.join(@base_uri, request_uri)

    @client = @adapter.new(uri: uri)
  end

  private

  attr_accessor :client
end
