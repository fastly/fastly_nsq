# frozen_string_literal: true

require 'fastly_nsq/http'

class FastlyNsq::Http::Nsqd
  extend Forwardable
  def_delegator :client, :get
  def_delegator :client, :post

  BASE_NSQD_URL = ENV.fetch 'NSQD_URL', "https://#{ENV.fetch('NSQD_HTTPS_ADDRESS', '')}"

  def self.ping
    new(request_uri: '/ping').get
  end

  def self.info
    new(request_uri: '/info').get
  end

  def self.stats(topic: nil, channel: nil, format: 'json')
    # format can be 'text' or 'json'
    # topic and channel are for filtering
    params = { format: 'json' }
    params[:topic] = topic if topic
    params[:channel] = channel if channel
    new(request_uri: '/stats').get(params)
  end

  def self.pub(topic:, defer: nil, message:)
    # defer is ms delay to apply to message delivery
    params = { topic: topic }
    params[:defer] = defer if defer
    new(request_uri: '/pub').post(params, message)
  end

  def self.mpub(topic:, binary: 'false', message:)
    # \n seperate messages in message
    params = { topic: topic, binary: binary}
    new(request_uri: '/mpub').post({format: 'json'}, message)
  end

  def self.config_nsqlookupd_tcp_addresses
    new(request_uri: '/config/nsqlookupd_tcp_addresses').get
  end

  def self.topic_create(topic:)
    new(request_uri: '/topic/create').post(topic: topic)
  end

  def self.topic_delete(topic:)
    new(request_uri: '/topic/delete').post(topic: topic)
  end

  def self.topic_empty(topic:)
    new(request_uri: '/topic/empty').post(topic: topic)
  end

  def self.topic_pause(topic:)
    new(request_uri: '/topic/pause').post(topic: topic)
  end

  def self.topic_unpause(topic:)
    new(request_uri: '/topic/unpause').post(topic: topic)
  end

  def self.channel_create(topic:, channel:)
    new(request_uri: '/channel/create').post(topic: topic, channel: channel)
  end

  def self.channel_delete(topic:, channel:)
    new(request_uri: '/channel/delete').post(topic: topic, channel: channel)
  end

  def self.channel_empty(topic:, channel:)
    new(request_uri: '/channel/empty').post(topic: topic, channel: channel)
  end

  def self.channel_pause(topic:, channel:)
    new(request_uri: '/channel/pause').post(topic: topic, channel: channel)
  end

  def self.channel_unpause(topic:, channel:)
    new(request_uri: '/channel/unpause').post(topic: topic, channel: channel)
  end

  def initialize(request_uri:, base_uri: nil, requester: nil)
    @base_uri = base_uri || BASE_NSQD_URL
    @requester = requester || FastlyNsq::Http
    uri = URI.join(@base_uri, request_uri)

    @client = @requester.new(uri: uri)
    @client.use_ssl
  end

  private

  attr_accessor :client
end
