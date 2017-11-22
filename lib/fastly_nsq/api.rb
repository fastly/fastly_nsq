# frozen_string_literal: true

require 'net/https'

class FastlyNsq::Http
  def initialize(uri:)
    @uri = uri
  end

  def get(data = nil)
    if data
      params = URI.encode_www_form(data)
      uri.query = params
    end
    req = Net::HTTP::Get.new(uri.request_uri)
    http.request(req)
  end

  def post(data, body = nil)
    params = URI.encode_www_form(data)
    uri.query = params
    req = Net::HTTP::Post.new(uri.request_uri)
    http.request(req, body)
  end

  def use_ssl
    return if ENV['NSQ_SSL_CERTIFICATE'].nil? || ENV['NSQ_SSL_KEY'].nil?
    http.use_ssl = true
    http.cert = cert
    http.key = key
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end

  private

  attr_reader :uri

  def http
    @http ||= Net::HTTP.new(uri.host, uri.port)
  end

  def cert
    @cert ||= OpenSSL::X509::Certificate.new(File.read(ENV['NSQ_SSL_CERTIFICATE']))
  end

  def key
    @key ||= OpenSSL::PKey::RSA.new(File.read(ENV['NSQ_SSL_KEY']))
  end
end

class LookupAPI
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

  def initialize(request_uri:, base_uri: nil, requester: nil)
    @requester = requester || FastlyNsq::Http
    @base_uri = base_uri || BASE_NSQLOOKUPD_URL
    uri = URI.join(@base_uri, request_uri)

    @client = @requester.new(uri: uri)
  end

  private

  attr_accessor :client
end

class NsqAPI
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

  def self.stats(topic: nil, format: 'json', channel: nil)
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

  def self.config
    # TODO
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
