require 'spec_helper'

RSpec.describe FakeMessageQueue do
  describe '@@queue' do
    it 'is initalized as an empty array' do
      expect(FakeMessageQueue.queue).to eq []
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
      FakeMessageQueue.queue = ['hello']
      expect(FakeMessageQueue.queue.size).to eq 1

      FakeMessageQueue.reset!

      expect(FakeMessageQueue.queue).to be_empty
    end
  end
end

RSpec.describe FakeMessageQueue::Producer do
  after { FakeMessageQueue.reset! }

  let(:topic)    { 'death_star' }
  let(:producer) { FakeMessageQueue::Producer.new topic: topic }

  it 'adds a new message to the queue' do
    producer.write('hello')

    expect(FakeMessageQueue.queue.size).to eq 1
  end

  it 'has a `terminate` method which is a noop' do
    expect(producer).to respond_to(:terminate)
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
  let(:topic)    { 'death_star' }
  let(:channel)  { 'star_killer_base' }
  let(:consumer) { FakeMessageQueue::Consumer.new topic: topic, channel: channel }

  after do
    FakeMessageQueue.reset!
  end

  describe 'when there are no messages on the queue' do
    it 'tells you there are 0 messages in the queue' do
      expect(consumer.size).to eq 0
    end

    it 'blocks forever (until timeout) from #pop' do
      FakeMessageQueue.delay = 0.1
      delay = FakeMessageQueue.delay + 0.1

      expect do
        Timeout.timeout(delay) do
          consumer.pop
        end
      end.to raise_error(Timeout::Error)
    end

    it 'returns nil from #pop_without_blocking' do
      popped_message = consumer.pop_without_blocking

      expect(popped_message).to be_nil
    end
  end

  describe 'when there is a message on the queue' do
    let(:message) { FakeMessageQueue::Message.new 'hello' }
    before { FakeMessageQueue.queue = [message] }

    it 'tells you there are messages in the queue' do
      expect(consumer.size).to eq 1
    end

    it 'returns a message immediately from #pop' do
      popped_message = consumer.pop

      expect(popped_message).to eq message
    end

    it 'returns a message immediately from #pop_without_blocking' do
      popped_message = consumer.pop_without_blocking

      expect(popped_message).to eq message
    end
  end

  describe '#terminate' do
    it 'has a terminate method which is a noop' do
      consumer = instance_double('FakeMessageQueue::Consumer')
      allow(consumer).to receive(:terminate)
    end
  end
end
