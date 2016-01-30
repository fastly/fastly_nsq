require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/core_ext/module/introspection'

class FakeMessageQueue
  cattr_accessor :queue

  def self.producer(topic:)
    @producer ||= Producer.new
  end

  def self.consumer(topic:, channel:)
    @consumer ||= Consumer.new
  end

  def self.reset!
    self.queue = []
  end

  class Producer
    def write(string)
      message = Message.new(string)
      queue.push(message)
    end

    private

    def queue
      self.class.parent.queue
    end
  end

  class Consumer
    def pop
      queue.pop
    end

    def size
      queue.size
    end

    private

    def queue
      self.class.parent.queue
    end
  end

  class Message
    attr_reader :body

    def initialize(body)
      @body = body
    end

    def finish
    end
  end
end
