require 'spec_helper'

RSpec.describe FastlyNsq::FakeBackend do
  describe '@@queue' do
    it 'is initalized as an empty array' do
      expect(FastlyNsq::FakeBackend.queue).to eq []
    end
  end

  describe '@@logger' do
    after do
      FastlyNsq::FakeBackend.logger = Logger.new(nil)
    end

    it 'is initalized as an empty Ruby Logger' do
      expect(FastlyNsq::FakeBackend.logger).to be_a Logger
    end

    it 'can be set and retrieved' do
      logger = double('some logger')
      FastlyNsq::FakeBackend.logger = logger

      expect(FastlyNsq::FakeBackend.logger).to eq logger
    end
  end

  describe '.reset!' do
    it 'resets the fake message queue' do
      FastlyNsq::FakeBackend.queue = ['hello']
      expect(FastlyNsq::FakeBackend.queue.size).to eq 1

      FastlyNsq::FakeBackend.reset!

      expect(FastlyNsq::FakeBackend.queue).to be_empty
    end
  end
end

RSpec.describe FastlyNsq::FakeBackend::Producer do
  let(:topic)    { 'death_star' }
  let(:producer) { FastlyNsq::FakeBackend::Producer.new topic: topic }

  it 'adds a new message to the queue' do
    producer.write('hello')

    expect(FastlyNsq::FakeBackend.queue.size).to eq 1
  end

  it 'has a `terminate` method which is a noop' do
    expect(producer).to respond_to(:terminate)
  end
end

RSpec.describe FastlyNsq::FakeBackend::Message do
  describe '#body' do
    it 'returns the body of the message' do
      topic = 'death_star'
      content = 'hello'
      producer = FastlyNsq::FakeBackend::Producer.new(
        nsqd: ENV.fetch('NSQD_TCP_ADDRESS'),
        topic: topic,
      )
      producer.write(content)

      message = FastlyNsq::FakeBackend.queue.pop
      body = message.body

      expect(content).to eq body
    end
  end
end

RSpec.describe FastlyNsq::FakeBackend::Consumer do
  let(:topic)    { 'death_star' }
  let(:channel)  { 'star_killer_base' }
  let(:consumer) { FastlyNsq::FakeBackend::Consumer.new topic: topic, channel: channel }

  describe 'when there are no messages on the queue' do
    it 'tells you there are 0 messages in the queue' do
      expect(consumer.size).to eq 0
    end

    it 'blocks forever (until timeout) from #pop' do
      FastlyNsq::FakeBackend.delay = 0.1
      delay = FastlyNsq::FakeBackend.delay + 0.1

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
    let(:message) { FastlyNsq::FakeBackend::Message.new 'hello' }
    before { FastlyNsq::FakeBackend.queue = [message] }

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
      consumer = instance_double('FastlyNsq::FakeBackend::Consumer')
      allow(consumer).to receive(:terminate)
    end
  end
end
