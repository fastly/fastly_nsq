# frozen_string_literal: true

require 'fastly_nsq/message'
require 'fastly_nsq/manager'
require 'fastly_nsq/safe_thread'
require 'fastly_nsq/listener/config'

module FastlyNsq
  class Listener
    include FastlyNsq::SafeThread

    def self.listen_to(*args)
      new(*args).go
    end

    def initialize(topic:, processor:, channel: nil, consumer: nil, **options)
      @consumer     = consumer || FastlyNsq::Consumer.new(topic: topic, channel: channel)
      @done         = false
      @logger       = options.fetch :logger, FastlyNsq.logger
      @manager      = options[:manager] || FastlyNsq::Manager.new
      @preprocessor = options[:preprocessor]
      @processor    = processor
      @thread       = nil
      @topic        = topic
    end

    def identity
      {
        consumer:     @consumer,
        logger:       @logger,
        manager:      @manager,
        preprocessor: @preprocessor,
        processor:    @processor,
        topic:        @topic,
      }
    end

    def reset_then_dup
      reset
      dup
    end

    def start
      @logger.info { "> Listener Started: topic #{@topic}" }
      @thread ||= safe_thread('listener', &method(:go))
    end

    def go(run_once: false)
      until @done
        next_message do |message|
          log message
          preprocess message
          @processor.process message
        end

        terminate if run_once
      end

      @manager.listener_stopped(self)
    rescue FastlyNsq::Shutdown
      @manager.listener_stopped(self)
    rescue Exception => e # rubocop:disable Lint/RescueException
      @logger.error e.inspect
      @manager.listener_killed(self)
    end

    def status
      @thread.status if @thread
    end

    def terminate
      @done = true
      cleanup
      return unless @thread
      @logger.info "< Listener TERM: topic #{@topic}"
      # Interrupt a Consumer blocking in pop with no messages otherwise it will never shutdown
      @thread.raise FastlyNsq::Shutdown if @consumer.empty?
    end

    def kill
      @done = true
      cleanup
      return unless @thread
      @logger.info "< Listener KILL: topic #{@topic}"
      @thread.raise FastlyNsq::Shutdown
    end

    private

    def log(message)
      @logger.info "[NSQ] Message received on topic [#{@topic}]: #{message}" if @logger
    end

    def cleanup
      @consumer.terminate
      @logger.info "< Consumer terminated: topic [#{@topic}]"
    end

    def next_message
      nsq_message = @consumer.pop # TODO: consumer.pop do |message|
      message = FastlyNsq::Message.new(nsq_message)
      result  = yield message
      message.finish if result
    end

    def preprocess(message)
      @preprocessor.call(message) if @preprocessor
    end

    def reset
      @done = false
      @thread = nil
      self
    end
  end
end

class FastlyNsq::Shutdown < StandardError; end
