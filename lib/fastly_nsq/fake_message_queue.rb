module FakeMessageQueue
  @@queue = Queue.new

  def self.queue
    @@queue
  end

  def self.reset!
    self.queue.clear
  end

  class Producer
    def initialize(nsqd:, topic:)
    end

    def write(string)
      message = Message.new(string)
      queue.push(message)
    end

    def terminate
      # noop
    end

    private

    def queue
      FakeMessageQueue.queue
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

    def terminate
      # noop
    end

    private

    def queue
      FakeMessageQueue.queue
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
