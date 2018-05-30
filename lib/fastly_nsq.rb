# frozen_string_literal: true

require 'nsq'
require 'concurrent'
require 'fc'
require 'set'
require 'logger'
require 'forwardable'
require 'digest/md5'

module FastlyNsq
  NotConnectedError = Class.new(StandardError)
  ConnectionFailed = Class.new(StandardError)

  LIFECYCLE_EVENTS = %i[startup shutdown heartbeat].freeze

  class << self
    attr_accessor :channel
    attr_accessor :preprocessor
    attr_accessor :max_attempts
    attr_writer :logger

    def events
      @events ||= LIFECYCLE_EVENTS.each_with_object({}) { |e, a| a[e] = [] }
    end

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

    # Register a block to run at a point in the lifecycle.
    # :startup, :heartbeat or :shutdown are valid events.
    #
    #   FastlyNsq.configure do |config|
    #     config.on(:shutdown) do
    #       puts "Goodbye cruel world!"
    #     end
    #   end
    def on(event, &block)
      event = event.to_sym
      raise ArgumentError, "Invalid event name: #{event}" unless LIFECYCLE_EVENTS.include?(event)
      events[event] << block
    end

    def fire_event(event)
      blocks = FastlyNsq.events.fetch(event)
      blocks.each do |block|
        begin
          block.call
        rescue => e
          logger.error "[#{event}] #{e.inspect}"
        end
      end
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
