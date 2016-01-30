require 'test_helper'

describe FakeMessageQueue do
  describe '.producer' do
    it 'returns an instance of the fake producer' do
      producer = FakeMessageQueue.producer(topic: 'any_topic')

      assert_kind_of FakeMessageQueue::Producer, producer
    end
  end

  describe '.consumer' do
    it 'returns an instance of the fake consumer' do
      consumer = FakeMessageQueue.consumer(topic: 'any_topic', channel: 'any')

      assert_kind_of FakeMessageQueue::Consumer, consumer
    end
  end

  describe '.reset!' do
    it 'resets the fake message queue' do
      FakeMessageQueue.queue = ['hello']

      FakeMessageQueue.reset!

      assert_empty FakeMessageQueue.queue
    end
  end

  describe 'Producer' do
    describe '#write' do
      it 'adds a new message to the queue' do
        FakeMessageQueue::Producer.new.write('hello')

        assert_equal 1, FakeMessageQueue.queue.size
      end
    end
  end

  describe 'Message' do
    describe '#body' do
      it 'returns the body of the message' do
        content = 'hello'
        FakeMessageQueue::Producer.new.write(content)

        message = FakeMessageQueue.queue.first
        body = message.body

        assert_equal content, body
      end
    end
  end

  describe 'Consumer' do
    describe '#size' do
      it 'tells you how many messages are in the queue' do
        FakeMessageQueue.queue = ['hello']

        queue_size = FakeMessageQueue::Consumer.new.size

        assert_equal 1, queue_size
      end
    end

    describe '#pop' do
      it 'returns the last message off of the queue' do
        message = FakeMessageQueue::Message.new('hello')
        FakeMessageQueue.queue = [message]

        popped_message = FakeMessageQueue::Consumer.new.pop

        assert_equal message, popped_message
      end
    end
  end
end
