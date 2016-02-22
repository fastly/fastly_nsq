require 'spec_helper'

RSpec.describe FakeMessageQueue do
  describe '@@queue' do
    it 'is initalized as an empty array' do
      expect(FakeMessageQueue.queue).to eq []
    end
  end

  describe '.reset!' do
    it 'resets the fake message queue' do
      FakeMessageQueue.queue = ['hello']
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
      FakeMessageQueue.queue = ['hello']
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
    it 'returns the last message off of the queue' do
      message = FakeMessageQueue::Message.new('hello')
      FakeMessageQueue.queue = [message]
      topic = 'death_star'
      channel = 'star_killer_base'

      consumer = FakeMessageQueue::Consumer.new(
        nsqlookupd: ENV.fetch('NSQLOOKUPD_HTTP_ADDRESS'),
        topic: topic,
        channel: channel,
      )
      popped_message = consumer.pop

      expect(popped_message). to eq message
    end
  end
end
