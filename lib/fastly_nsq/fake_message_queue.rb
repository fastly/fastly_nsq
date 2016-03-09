module FakeMessageQueue
  @@queue = []

  def self.queue
    @@queue
  end

  def self.queue=(message)
    @@queue = message
  end

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

    def terminate
      # noop
    end

    private

    def queue
      FakeMessageQueue.queue
    end
  end

  class Consumer
    SECONDS_BETWEEN_MESSAGE_QUEUE_CHECKS = 1

    def initialize(nsqlookupd:, topic:, channel:)
    end

    def pop
      message = nil

      until message do
        message = queue.pop
        sleep SECONDS_BETWEEN_MESSAGE_QUEUE_CHECKS
      end

      message
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
