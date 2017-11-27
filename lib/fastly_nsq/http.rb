# frozen_string_literal: true

require 'net/https'
require 'fastly_nsq/http/nsqd'
require 'fastly_nsq/http/nsqlookupd'

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
