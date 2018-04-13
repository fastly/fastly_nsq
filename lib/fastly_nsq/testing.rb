# frozen_string_literal: true

module FastlyNsq
  class Testing
    class << self
      attr_accessor :__test_mode

      def __set_test_mode(mode)
        if block_given?
          current_mode = __test_mode
          begin
            self.__test_mode = mode
            yield
          ensure
            self.__test_mode = current_mode
          end
        else
          self.__test_mode = mode
        end
      end

      def disable!(&block)
        __set_test_mode(:disable, &block)
      end

      def fake!(&block)
        __set_test_mode(:fake, &block)
      end

      def inline!(&block)
        __set_test_mode(:inline, &block)
      end

      def enabled?
        __test_mode != :disable
      end

      def disabled?
        __test_mode == :disable
      end

      def fake?
        __test_mode == :fake
      end

      def inline?
        __test_mode == :inline
      end

      def reset!
        return unless enabled?
        FastlyNsq::Messages.messages.clear
      end
    end
  end

  module Messages
    def self.messages
      @messages ||= Hash.new { |h, k| h[k] = [] }
    end
  end

  class TestMessage
    attr_reader :raw_body
    attr_reader :attempts
    attr_reader :id

    def initialize(raw_body)
      @raw_body = raw_body
      @id       = Digest::SHA1.hexdigest(raw_body.to_s + Time.now.to_s)
      @attempts = 0
    end

    def body
      JSON.parse(JSON.dump(raw_body))
    rescue JSON::ParserError
      raw_body
    end

    def finish
      FastlyNsq::Messages.messages.find { |_, ms| ms.delete(self) }
    end

    def requeue(*)
      @attempts += 1
      true
    end
  end

  module ProducerTesting
    def connected?
      return super unless FastlyNsq::Testing.enabled?
      @connected = true if @connected.nil?
      @connected
    end

    def terminate
      return super unless FastlyNsq::Testing.enabled?

      @connected = false
    end

    def write(message)
      return super unless FastlyNsq::Testing.enabled?

      raise FastlyNsq::NotConnectedError unless connected?

      test_message = TestMessage.new(message)
      FastlyNsq::Messages.messages[topic] << test_message

      if FastlyNsq::Testing.inline?
        listener = FastlyNsq.manager.topic_listeners[topic]
        return unless listener
        listener.call test_message
      end

      true
    end

    def connection
      return super unless FastlyNsq::Testing.enabled?
      return nil unless connected?
      self
    end

    def connect
      return super unless FastlyNsq::Testing.enabled?
      @connected = true
    end

    def messages
      raise NoMethodError unless FastlyNsq::Testing.enabled?

      FastlyNsq::Messages.messages[topic]
    end
  end

  Producer.prepend(ProducerTesting)

  module ListenerTesting
    module ClassMethods
      def messages(topic = nil)
        return FastlyNsq::Messages.messages.values.flatten unless topic

        FastlyNsq::Messages.messages[topic]
      end

      def drain(topic = nil)
        topics = topic ? [topic] : FastlyNsq::Messages.messages.keys
        topics.each do |t|
          messages = FastlyNsq::Messages.messages[t]
          next unless messages.any?
          listener = FastlyNsq.manager.topic_listeners[t]
          next unless listener

          messages.dup.each { |message| listener.call(message) }
        end
      end

      def clear
        FastlyNsq::Messages.messages.clear
      end
    end

    def self.prepended(klass)
      klass.prepend(ClassMethods)
      super
    end

    def terminate
      return super unless FastlyNsq::Testing.enabled?

      @connected = false
    end

    def connected?
      return super unless FastlyNsq::Testing.enabled?
      @connected = true if @connected.nil?

      @connected
    end

    def drain
      raise NoMethodError unless FastlyNsq::Testing.enabled?

      self.class.drain(topic)
    end

    def messages
      raise NoMethodError unless FastlyNsq::Testing.enabled?

      self.class.messages(topic)
    end
  end

  FastlyNsq::Listener.prepend(ListenerTesting)

  module ConsumerTesting
    module ClassMethods
      def messages(topic = nil)
        return FastlyNsq::Messages.messages.values.flatten unless topic

        FastlyNsq::Messages.messages[topic]
      end

      def clear
        FastlyNsq::Messages.messages.clear
      end
    end

    def self.prepended(klass)
      klass.prepend(ClassMethods)
      super
    end

    def terminate
      FastlyNsq::Testing.enabled? || super
    end

    def empty?
      FastlyNsq::Testing.enabled? ? messages.empty? : super
    end

    def size
      FastlyNsq::Testing.enabled? ? messages.size : super
    end

    def terminated?
      FastlyNsq::Testing.enabled? ? false : super
    end

    def messages
      raise NoMethodError unless FastlyNsq::Testing.enabled?

      FastlyNsq::Messages.messages[topic]
    end
  end

  FastlyNsq::Consumer.prepend(ConsumerTesting)
end

# Default to fake testing
FastlyNsq::Testing.fake!
