require 'test_helper'

describe FakeMessageQueue do
  describe '@@queue' do
    it 'is initalized as an empty array' do
      assert_equal [], FakeMessageQueue.queue
    end
  end

  describe '.reset!' do
    it 'resets the fake message queue' do
      FakeMessageQueue.queue = ['hello']
      assert_equal 1, FakeMessageQueue.queue.size

      FakeMessageQueue.reset!

      assert_empty FakeMessageQueue.queue
    end
  end
end

describe FakeMessageQueue::Producer do
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

      assert_equal 1, FakeMessageQueue.queue.size
    end
  end
end

describe FakeMessageQueue::Message do
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

      assert_equal content, body
    end
  end
end

describe FakeMessageQueue::Consumer do
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

      assert_equal 1, queue_size
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

      assert_equal message, popped_message
    end
  end
end
