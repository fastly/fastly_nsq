module FakeMessageQueue
  @@logger = Logger.new(nil)
  @@delay  = 0.5
  @@queue  = []

  def self.queue
    @@queue
  end

  def self.queue=(message)
    @@queue = message
  end

  def self.reset!
    self.queue = []
  end

  def self.logger=(logger)
    @@logger = logger
  end

  def self.logger
    @@logger
  end

  def self.delay
    @@delay
  end

  def self.delay=(delay)
    @@delay = delay
  end

  class Producer
    def initialize(nsqd:, topic:, ssl_context: nil)
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
    def initialize(nsqlookupd: nil, topic:, channel:, ssl_context: nil)
    end

    def pop(delay=FakeMessageQueue.delay)
      message = nil

      until message
        message = queue.pop
        sleep delay
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
