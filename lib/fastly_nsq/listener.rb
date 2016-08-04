module FastlyNsq
  class Listener
    def self.listen_to(**args)
      new(**args).go
    end

    def initialize(topic:, processor:, channel: nil, consumer: nil, preprocessor: nil)
      @topic        = topic
      @preprocessor = preprocessor
      @processor    = processor
      @consumer     = consumer || FastlyNsq::Consumer.new(topic: topic, channel: channel)
    end

    def go(run_once: false)
      exit_on 'INT'
      exit_on 'TERM'

      loop do
        next_message do |message|
          preprocessor.call(message.body) if preprocessor
          processor.process(message.body, topic)
        end

        break if run_once
      end

      consumer.terminate
    end

    private

    attr_reader :topic, :consumer, :preprocessor, :processor

    def next_message
      message = consumer.pop # TODO: consumer.pop do |message|
      result  = yield message
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
