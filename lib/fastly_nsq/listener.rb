# frozen_string_literal: true
require 'fastly_nsq/message'
require 'fastly_nsq/manager'
require 'fastly_nsq/safe_thread'

module FastlyNsq
  class Listener
    include FastlyNsq::SafeThread

    def self.listen_to(*args)
      new(*args).go
    end

    def initialize(topic:, processor:, channel: nil, consumer: nil, **options)
      @done         = false
      @thread       = nil
      @topic        = topic
      @processor    = processor
      @consumer     = consumer || FastlyNsq::Consumer.new(topic: topic, channel: channel)
      @logger       = options.fetch :logger, FastlyNsq.logger
      @preprocessor = options[:preprocessor]
      @manager      = options[:manager] || FastlyNsq::Manager.new
    end

    def dup
      duplicate = super
      duplicate.reset
    end

    def reset
      @done = false
      @thread = nil
      self
    end

    def start
      logger.info "> Listener Started: topic #{topic}"
      @thread ||= safe_thread('listener', &method(:go))
    end

    def go(run_once: false)
      until @done
        next_message do |message|
          log message
          preprocess message
          processor.process message
        end

        @done = true if run_once
      end

      @manager.listener_stopped(self)
    rescue FastlyNsq::Shutdown
      @manager.listener_stopped(self)
    rescue Exception => ex # rubocop:disable Lint/RescueException
      logger.error ex.inspect
      @manager.listener_killed(self)
    ensure
      cleanup
    end

    def status
      @thread.status
    end

    def terminate
      @done = true
      return unless @thread
      logger.info "< Listener TERM: topic #{topic}"
    end

    def kill
      @done = true
      return unless @thread
      logger.info "< Listener KILL: topic #{topic}"
      @thread.raise FastlyNsq::Shutdown
    end

    private

    attr_reader :topic, :consumer, :preprocessor, :processor, :logger

    def log(message)
      logger.info "[NSQ] Message Received: #{message}" if logger
    end

    def cleanup
      consumer.terminate
      logger.info '< Consumer terminated'
    end

    def next_message
      message = consumer.pop # TODO: consumer.pop do |message|
      result  = yield FastlyNsq::Message.new(message.body)
      message.finish if result
    end

    def preprocess(message)
      preprocessor.call(message) if preprocessor
    end
  end
end

class FastlyNsq::Shutdown < StandardError; end

require 'fastly_nsq/listener/config'
