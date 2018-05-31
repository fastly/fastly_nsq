# frozen_string_literal: true

require 'net/https'
require 'fastly_nsq/http/nsqd'
require 'fastly_nsq/http/nsqlookupd'

##
# Adapter class for HTTP requests to NSQD
#
# @example
#   uri = URI.join(nsqd_url, '/info')
#   client = FastlyNsq::Http.new(uri: uri)
#   client.use_ssl
#
# @see FastlyNsq::Http::Nsqd
# @see FastlyNsq::Http::Nsqlookupd
class FastlyNsq::Http
  def initialize(uri:, cert_filename: ENV['NSQ_SSL_CERTIFICATE'], key_filename: ENV['NSQ_SSL_KEY'])
    @uri = uri.is_a?(URI) ? uri : URI.parse(uri)
    @cert_filename = cert_filename
    @key_filename = key_filename
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
    return unless can_use_ssl?
    http.use_ssl = true
    http.cert = cert
    http.key = key
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end

  private

  attr_reader :cert_filename, :key_filename, :uri

  def http
    @http ||= Net::HTTP.new(uri.host, uri.port)
  end

  def can_use_ssl?
    !(cert_filename.nil? || key_filename.nil?)
  end

  def cert
    @cert ||= OpenSSL::X509::Certificate.new(File.read(cert_filename))
  end

  def key
    @key ||= OpenSSL::PKey::RSA.new(File.read(key_filename))
  end
end
