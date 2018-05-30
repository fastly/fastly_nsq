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
    # @return [String] NSQ Channel
    attr_accessor :channel

    # @return [Proc] global preprocessor
    attr_accessor :preprocessor

    # Maximum number of times an NSQ message will be attempted.
    # When set to +nil+, the number of attempts will be unlimited.
    # @return [Integer]
    attr_accessor :max_attempts

    # @return [Logger]
    attr_writer :logger

    ##
    # Map of lifecycle events
    # @return [Hash]
    def events
      @events ||= LIFECYCLE_EVENTS.each_with_object({}) { |e, a| a[e] = [] }
    end

    ##
    # Create a FastlyNsq::Listener
    #
    # @param topic [String] NSQ topic on which to listen
    # @param processor [Proc] processor that will be +call+ed per message
    # @param options [Hash] additional options that are passed to FastlyNsq::Listener's constructor
    # @return FastlyNsq::Listener
    def listen(topic, processor, **options)
      FastlyNsq::Listener.new(topic: topic, processor: processor, **options)
    end

    def logger
      @logger ||= Logger.new(nil)
    end

    ##
    # Configuration for FastlyNsq
    # @example
    #   FastlyNsq.configure do |config|
    #     config.channel = 'Z'
    #     config.logger = Logger.new
    #   end
    # @example
    #   FastlyNsq.configure do |config|
    #     config.channel = 'fnsq'
    #     config.logger = Logger.new
    #     config.preprocessor = ->(_) { FastlyNsq.logger.info 'PREPROCESSESES' }
    #     lc.listen 'posts', ->(m) { puts "posts: #{m.body}" }
    #     lc.listen 'blogs', ->(m) { puts "blogs: #{m.body}" }, priority: 3
    #   end
    def configure
      yield self
    end

    ##
    # Returns a new FastlyNsq::Manager or the memoized
    # instance +@manager+.
    # @return [FastlyNsq::Manager]
    def manager
      @manager ||= FastlyNsq::Manager.new
    end

    ##
    # Set a new manager and transfer listeners to the new manager.
    # @param manager [FastlyNsq::Manager]
    # @return [FastlyNsq::Manager]
    def manager=(manager)
      @manager&.transfer(manager)
      @manager = manager
    end

    ##
    # Return an array of NSQ lookupd http addresses sourced from ENV['NSQLOOKUPD_HTTP_ADDRESS']
    # @return [Array<String>] list of nsqlookupd http addresses
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
