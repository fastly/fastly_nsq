# frozen_string_literal: true

require 'nsq'
require 'concurrent'
require 'fc'
require 'set'
require 'logger'
require 'forwardable'

module FastlyNsq
  NotConnectedError = Class.new(StandardError)
  ConnectionFailed = Class.new(StandardError)

  class << self
    attr_accessor :channel
    attr_accessor :preprocessor
    attr_writer :logger

    def listen(topic, processor, **options)
      FastlyNsq::Listener.new(topic: topic, processor: processor, **options)
    end

    def logger
      @logger ||= Logger.new(nil)
    end

    def configure
      yield self
    end

    def manager
      @manager ||= FastlyNsq::Manager.new
    end

    def manager=(manager)
      @manager&.transfer(manager)
      @manager = manager
    end

    def lookupd_http_addresses
      ENV.fetch('NSQLOOKUPD_HTTP_ADDRESS').split(',').map(&:strip)
    end
  end
end

require 'fastly_nsq/consumer'
require 'fastly_nsq/feeder'
require 'fastly_nsq/launcher'
require 'fastly_nsq/listener'
require 'fastly_nsq/manager'
require 'fastly_nsq/message'
require 'fastly_nsq/messenger'
require 'fastly_nsq/priority_queue'
require 'fastly_nsq/priority_thread_pool'
require 'fastly_nsq/producer'
require 'fastly_nsq/tls_options'
require 'fastly_nsq/version'
