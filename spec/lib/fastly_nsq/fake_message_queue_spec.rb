require 'spec_helper'

RSpec.describe FakeMessageQueue do
  describe '@@queue' do
    it 'is initalized as an empty Ruby Queue' do
      queue = FakeMessageQueue.queue

      expect(queue).to be_a Thread::Queue
      expect(queue).to be_empty
    end
  end

  describe '@@logger' do
    after do
      FakeMessageQueue.logger = Logger.new(nil)
    end

    it 'is initalized as an empty Ruby Logger' do
      expect(FakeMessageQueue.logger).to be_a Logger
    end

    it 'can be set and retrieved' do
      logger = double('some logger')
      FakeMessageQueue.logger = logger

      expect(FakeMessageQueue.logger).to eq logger
    end
  end

  describe '.reset!' do
    it 'resets the fake message queue' do
      FakeMessageQueue.queue.push('hello')
      expect(FakeMessageQueue.queue.size).to eq 1

      FakeMessageQueue.reset!

      expect(FakeMessageQueue.queue).to be_empty
    end
  end
end

RSpec.describe FakeMessageQueue::Producer do
  after do
    FakeMessageQueue.reset!
  end

  describe '#write' do
    it 'adds a new message to the queue' do
      topic = 'death_star'

      producer = FakeMessageQueue::Producer.new(
        nsqd: ENV.fetch('NSQD_TCP_ADDRESS'),
        topic: topic,
      )
      producer.write('hello')

      expect(FakeMessageQueue.queue.size).to eq 1
    end
  end

  describe '#terminate' do
    it 'has a terminate method which is a noop' do
      producer = instance_double('FakeMessageQueue::Producer')
      allow(producer).to receive(:terminate)
    end
  end
end

RSpec.describe FakeMessageQueue::Message do
  after do
    FakeMessageQueue.reset!
  end

  describe '#body' do
    it 'returns the body of the message' do
      topic = 'death_star'
      content = 'hello'
      producer = FakeMessageQueue::Producer.new(
        nsqd: ENV.fetch('NSQD_TCP_ADDRESS'),
        topic: topic,
      )
      producer.write(content)

      message = FakeMessageQueue.queue.pop
      body = message.body

      expect(content).to eq body
    end
  end
end

RSpec.describe FakeMessageQueue::Consumer do
  after do
    FakeMessageQueue.reset!
  end

  describe '#size' do
    it 'tells you how many messages are in the queue' do
      FakeMessageQueue.queue.push('hello')
      topic = 'death_star'
      channel = 'star_killer_base'

      consumer = FakeMessageQueue::Consumer.new(
        nsqlookupd: ENV.fetch('NSQLOOKUPD_HTTP_ADDRESS'),
        topic: topic,
        channel: channel,
      )
      queue_size = consumer.size

      expect(queue_size).to eq 1
    end
  end

  describe '#pop' do
    context 'when there is a message on the queue' do
      it 'returns the last message off of the queue' do
        message = FakeMessageQueue::Message.new('hello')
        FakeMessageQueue.queue.push(message)
        topic = 'death_star'
        channel = 'star_killer_base'

        consumer = FakeMessageQueue::Consumer.new(
          nsqlookupd: ENV.fetch('NSQLOOKUPD_HTTP_ADDRESS'),
          topic: topic,
          channel: channel,
        )
        popped_message = consumer.pop

        expect(popped_message).to eq message
      end
    end

    context 'when there no message on the queue' do
      it 'blocks on the process, waiting for a message ' do
        FakeMessageQueue.reset!
        topic = 'death_star'
        channel = 'star_killer_base'

        consumer = FakeMessageQueue::Consumer.new(
          nsqlookupd: ENV.fetch('NSQLOOKUPD_HTTP_ADDRESS'),
          topic: topic,
          channel: channel,
        )

        expect {
          Timeout::timeout(0.1) do
            consumer.pop
          end
        }.to raise_error(Timeout::Error)
      end
    end
  end

  describe '#terminate' do
    it 'has a terminate method which is a noop' do
      consumer = instance_double('FakeMessageQueue::Consumer')
      allow(consumer).to receive(:terminate)
    end
  end
end
