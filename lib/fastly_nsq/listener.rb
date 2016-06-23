module FastlyNsq
  class Listener
    def self.listen_to(**args)
      new(**args).go
    end
    
    def initialize(topic:, processor:, channel: nil, consumer: nil)
      @topic     = topic
      @processor = processor
      @consumer  = consumer || FastlyNsq::Consumer.new(topic: topic, channel: channel)
    end

    def go(limit: false)
      Signal.trap('INT') do
        consumer.terminate
        exit        
      end

      Signal.trap('TERM') do
        consumer.terminate
        exit
      end

      loop do
        next_message do |message|
          processor.process(message.body, topic)
        end

        break if limit
      end
      
      consumer.terminate
    end

    private

    attr_reader :topic, :consumer, :processor

    def next_message
      message = consumer.pop # TODO: consumer.pop do |message|
      result  = yield message
      message.finish if result
    end
  end
end
