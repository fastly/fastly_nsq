# frozen_string_literal: true

module FastlyNsq
  ##
  # Interface for testing FastlyNsq
  # @example
  #   require 'fastly_nsq/testing'
  #   FastlyNsq::Testing.enabled? #=> true
  #   FastlyNsq::Testing.disabled? #=> false

  #   producer = FastlyNsq::Producer.new(topic: topic)
  #   listener = FastlyNsq::Listener.new(topic: topic, channel: channel, processor: ->(m) { puts 'got: '+ m.body })

  #   FastlyNsq::Testing.fake! # default, messages accumulate on the listeners

  #   producer.write '{"foo":"bar"}'
  #   listener.messages.size #=> 1

  #   FastlyNsq::Testing.reset!  # remove all accumulated messages

  #   listener.messages.size #=> 0

  #   producer.write '{"foo":"bar"}'
  #   listener.messages.size #=> 1

  #   listener.drain
  #   # got: {"foo"=>"bar"}
  #   listener.messages.size #=> 0

  #   FastlyNsq::Testing.inline! # messages are processed as they are produced
  #   producer.write '{"foo":"bar"}'
  #   # got: {"foo"=>"bar"}
  #   listener.messages.size #=> 0

  #   FastlyNsq::Testing.disable! # do it live
  #   FastlyNsq::Testing.enable!  # re-enable testing mode
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

      ##
      # Creates a FastlyNsq::TestMessage that is used to create a FastlyNsq::Message where the underlying
      # +nsq_message+ is the TestMessage and not an Nsq::Message. This aids in testing application code that
      # is doing message processing
      #
      # @param data [String] NSQ message data
      # @param meta [String] NSQ message metadata
      #
      # @example
      #   test_message = FastlyNsq::Testing.message(data: post_data, meta: {})
      #   processor_klass.call(test_message)
      #   expect(Post.find(post_data['id']).not_to be nil
      def message(data:, meta: nil)
        test_message = FastlyNsq::TestMessage.new(JSON.dump('data' => data, 'meta' => meta))
        FastlyNsq::Message.new(test_message)
      end
    end
  end

  module Messages
    def self.messages
      @messages ||= Hash.new { |h, k| h[k] = [] }
    end
  end

  ##
  # Stub for Nsq::Message used for testing.
  # Use this class instead of a struct or test stubs
  # when testing application logic that requires a Nsq::Message.
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

    def connected?
      return super unless FastlyNsq::Testing.enabled?
      @connected = true if @connected.nil?

      @connected
    end

    def connect(*args)
      return super(*args) unless FastlyNsq::Testing.enabled?
      @connected = true
      Struct.new(:topic, :channel) do
        def connected?; end
      end.new 'fake_topic', 'fake_channel'
    end

    def empty?
      FastlyNsq::Testing.enabled? ? messages.empty? : super
    end

    def pop
      FastlyNsq::Testing.enabled? ? messages(topic)&.pop : super
    end

    def pop_without_blocking
      FastlyNsq::Testing.enabled? ? messages(topic)&.pop : super
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
