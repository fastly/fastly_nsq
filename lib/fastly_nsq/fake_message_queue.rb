require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/core_ext/module/introspection'

module FakeMessageQueue
  cattr_accessor :queue

  def self.reset!
    self.queue = []
  end

  class Producer
    def initialize(nsqd:, topic:)
    end

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
    def initialize(nsqlookupd:, topic:, channel:)
    end

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
