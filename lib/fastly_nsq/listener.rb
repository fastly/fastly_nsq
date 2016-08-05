require 'fastly_nsq/message'

module FastlyNsq
  class Listener
    def self.listen_to(**args)
      new(**args).go
    end

    def initialize(topic:, processor:, channel: nil, consumer: nil, logger: nil, preprocessor: nil)
      @topic        = topic
      @processor    = processor
      @consumer     = consumer || FastlyNsq::Consumer.new(topic: topic, channel: channel)
      @logger       = logger || FastlyNsq.logger
      @preprocessor = preprocessor
    end

    def go(run_once: false)
      exit_on 'INT'
      exit_on 'TERM'

      loop do
        next_message do |message|
          logger.info "[NSQ] Message Received: #{message}"
          preprocessor.call(message) if preprocessor
          processor.process(message, topic)
        end

        break if run_once
      end

      consumer.terminate
    end

    private

    attr_reader :topic, :consumer, :preprocessor, :processor, :logger

    def next_message
      message = consumer.pop # TODO: consumer.pop do |message|
      result  = yield FastlyNsq::Message.new(message.body)
      message.finish if result
    end

    def exit_on(signal)
      Signal.trap(signal) do
        consumer.terminate
        exit
      end
    end
  end
end
