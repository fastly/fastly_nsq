# frozen_string_literal: true

require 'fastly_nsq/http'

class FastlyNsq::Http::Nsqlookupd
  extend Forwardable
  def_delegator :client, :get

  BASE_NSQLOOKUPD_URL = "http://#{ENV.fetch('NSQLOOKUPD_HTTP_ADDRESS', '').split(',')[0]}"

  def self.lookup(topic:)
    new(request_uri: '/lookup').get(topic: topic)
  end

  def self.topics
    new(request_uri: '/topics').get
  end

  def self.channels(topic:)
    new(request_uri: '/channels').get(topic: topic)
  end

  def self.nodes
    new(request_uri: '/nodes').get
  end

  def self.delete_topic(topic:)
    new(request_uri: '/delete_topic').get(topic: topic)
  end

  def self.delete_channel(topic:, channel:)
    new(request_uri: '/delete_channel').get(topic: topic, channel: channel)
  end

  def self.tombstone_topic_producer(topic:, node:)
    # node identified by <broadcast_address>:<http_port>
    new(request_uri: '/tombstone_topic_producer').get(topic: topic, node: node)
  end

  def self.ping
    new(request_uri: '/ping').get
  end

  def self.info
    new(request_uri: '/info').get
  end

  def initialize(request_uri:, base_uri: nil, adapter: nil)
    @adapter = adapter || FastlyNsq::Http
    @base_uri = base_uri || BASE_NSQLOOKUPD_URL
    uri = URI.join(@base_uri, request_uri)

    @client = @adapter.new(uri: uri)
  end

  private

  attr_accessor :client
end
