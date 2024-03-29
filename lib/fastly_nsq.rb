# frozen_string_literal: true

require "nsq"
require "concurrent"
require "fc"
require "set"
require "logger"
require "forwardable"
require "digest/md5"

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

    # Set Maximum requeue timeout in milliseconds
    # @return [Integer]
    attr_writer :max_req_timeout

    # Maximum number of threads for FastlyNsq::PriorityThreadPool
    # @return [Integer]
    attr_writer :max_processing_pool_threads

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

    ##
    # Return logger or set logger to default.
    # @return [Logger]
    def logger
      return @logger if @logger

      self.logger = Logger.new($stderr)
    end

    ##
    # Set the logger and also set Nsq.logger
    # @params logger [Logger]
    def logger=(new_logger)
      @logger = Nsq.logger = new_logger
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
    # Maximum requeue timeout in milliseconds. This setting controls the
    # maximum value that will be sent from FastlyNsq::Message#requeue This
    # value should be less than or equal to the nsqd command line option
    # +max-req-timeout+. The default setting is 1 hour.
    # @return [Integer]
    # @see https://nsq.io/components/nsqd.html#command-line-options
    def max_req_timeout
      @max_req_timeout ||= ENV.fetch("MAX_REQ_TIMEOUT", 60 * 60 * 1_000).to_i
    end

    # Maximum number of threads for FastlyNsq::PriorityThreadPool
    # Default setting is 5 and can be set via ENV['MAX_PROCESSING_POOL_THREADS']
    # @return [Integer]
    def max_processing_pool_threads
      @max_processing_pool_threads ||= ENV.fetch("MAX_PROCESSING_POOL_THREADS", 5).to_i
    end

    ##
    # Return an array of NSQ lookupd http addresses sourced from ENV['NSQLOOKUPD_HTTP_ADDRESS']
    # @return [Array<String>] list of nsqlookupd http addresses
    def lookupd_http_addresses
      @lookups ||= ENV.fetch("NSQLOOKUPD_HTTP_ADDRESS", "").split(/, ?|\s+/).map(&:strip)
    end

    ##
    # Set the lookupd_http_addresses
    # @param lookups [Array] List of http lookupd addresses to use.
    def lookupd_http_addresses=(lookups)
      @lookups = lookups.nil? ? nil : Array(lookups)
    end

    ##
    # Return an array of NSQD TCP addresses for NSQ consumers. Defaults to the value of ENV['NSQD_CONSUMERS'].
    # ENV['NSQD_CONSUMERS'] must be a comma or space seperated string of NSQD addresses
    # @return [Array<String>] list of nsqd addresses
    def consumer_nsqds
      @consumer_nsqds ||= ENV.fetch("NSQD_CONSUMERS", "").split(/, ?|\s+/).map(&:strip)
    end

    ##
    # Set the consumer_nsqd addresses
    # @param nsqd_addresses [Array] List of consumer nsqd addresses to use
    def consumer_nsqds=(nsqd_addresses)
      @consumer_nsqds = nsqd_addresses.nil? ? nil : Array(nsqd_addresses)
    end

    ##
    # Return an array of NSQD TCP addresses for NSQ producers. Defaults to the value of ENV['NSQD_PRODUCERS'].
    # ENV['NSQD_PRODUCERS'] must be a comma or space seperated string of NSQD addresses
    # @return [Array<String>] list of nsqd addresses
    def producer_nsqds
      @producer_nsqds ||= ENV.fetch("NSQD_PRODUCERS", "").split(/, ?|\s+/).map(&:strip)
    end

    ##
    # Set the producer_nsqd addresses
    # @param nsqd_addresses [Array] List of producer nsqd addresses to use
    def producer_nsqds=(nsqd_addresses)
      @producer_nsqds = nsqd_addresses.nil? ? nil : Array(nsqd_addresses)
    end

    # Register a block to run at a point in the lifecycle.
    #
    # @example
    #   FastlyNsq.configure do |config|
    #     config.on(:shutdown) do
    #       puts "Goodbye cruel world!"
    #     end
    #   end
    # @param event [Symbol] Event to hook into.  One of :startup, :heartbeat or :shutdown.
    # @yield Proc to execute when event is triggered.
    def on(event, &block)
      event = event.to_sym
      raise ArgumentError, "Invalid event name: #{event}" unless LIFECYCLE_EVENTS.include?(event)
      events[event] << block
    end

    # Execute Procs assigned for the lifecycle event
    #
    # @param event [Symbol] Lifecycle event to trigger
    def fire_event(event)
      blocks = FastlyNsq.events.fetch(event)
      blocks.each do |block|
        block.call
      rescue => e
        logger.error "[#{event}] #{e.inspect}"
      end
    end

    # Instance of FastlyNsq::NewRelic
    #
    # @return [FastlyNsq::NewRelic]
    def tracer
      @tracer ||= FastlyNsq::NewRelic.new
    end
  end
end

require "fastly_nsq/consumer"
require "fastly_nsq/feeder"
require "fastly_nsq/launcher"
require "fastly_nsq/listener"
require "fastly_nsq/manager"
require "fastly_nsq/message"
require "fastly_nsq/messenger"
require "fastly_nsq/new_relic"
require "fastly_nsq/priority_queue"
require "fastly_nsq/priority_thread_pool"
require "fastly_nsq/producer"
require "fastly_nsq/tls_options"
require "fastly_nsq/version"
