require 'fastly_nsq/message'

module FastlyNsq
  class Listener
    class Config
      attr_reader :listeners

      def initialize
        @listeners = []
      end

      def add(topic_name, klass)
        FastlyNsq.logger.info("topic: #{topic_name} : klass #{klass}")
        listeners << { topic: topic_name, klass: klass }
      end
    end

    attr_accessor :full_args

    def self.listen_to(*args)
      new(*args).go
    end

    def self.setup(*args)
      new_listener = new(*args)
      new_listener.full_args = *args
      new_listener
    end

    def initialize(topic:, processor:, channel: nil, consumer: nil, **options)
      @done         = false
      @thread       = nil
      @topic        = topic
      @processor    = processor
      @consumer     = consumer || FastlyNsq::Consumer.new(topic: topic, channel: channel)
      @logger       = options.fetch :logger, FastlyNsq.logger
      @preprocessor = options[:preprocessor]
      @manager      = otpions[:manager]
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

        break if run_once
      end

      @manager.listener_stopped(self)
    rescue Exception => ex
      logger.error ex.inspect
      @manager.listener_killed(self)
    ensure
      cleanup
    end

    def status
      @thread.status
    end

    def terminate
      logger.info "< Listener TERM: topic #{topic}"
      @done = true
    end

    def kill
      logger.info "< Listener KILL: topic #{topic}"
      @done = true
      @thread.raise Exception # SHOULD BE MORE SPECIFIC
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

    def safe_thread(name, &block)
      Thread.new do
        Thread.current['fastly_nsq_label'] = name
        watchdog(name, &block)
      end
    end

    def watchdog(last_words)
      yield
    rescue Exception => ex
      FastlyNsq.logger.error ex
      FastlyNsq.logger.error last_words
      FastlyNsq.logger.error ex.backtrace.join("\n") unless ex.backtrace.nil?
      raise ex
    end
  end
end
