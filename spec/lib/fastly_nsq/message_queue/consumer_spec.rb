require 'spec_helper'

RSpec.describe MessageQueue::Consumer do
  describe '#connection' do
    describe 'when using the real queue', fake_queue: false do
      it 'returns an instance of the queue consumer' do
        allow(Nsq::Consumer).to receive(:new)
        topic = 'death_star'
        channel = 'star_killer_base'

        MessageQueue::Consumer.new(topic: topic, channel: channel).connection

        expect(Nsq::Consumer).to have_received(:new).
          with(
            nsqlookupd: ENV.fetch('NSQLOOKUPD_HTTP_ADDRESS'),
            topic: topic,
            channel: channel,
            ssl_context: nil,
          ).at_least(:once)
      end
    end

    describe 'when using the fake queue', fake_queue: true do
      it 'returns an instance of the queue consumer' do
        allow(FakeMessageQueue::Consumer).to receive(:new)
        topic = 'death_star'
        channel = 'star_killer_base'

        MessageQueue::Consumer.new(topic: topic, channel: channel).connection

        expect(FakeMessageQueue::Consumer).to have_received(:new).
          with(
            nsqlookupd: ENV.fetch('NSQLOOKUPD_HTTP_ADDRESS'),
            topic: topic,
            channel: channel,
            ssl_context: nil,
          ).at_least(:once)
      end
    end
  end

  describe 'when the ENV is set incorrectly' do
    it 'raises with a helpful error' do
      allow(ENV).to receive(:[]).with('FAKE_QUEUE').and_return('taco')
      topic = 'death_star'
      channel = 'star_killer_base'

      consumer = MessageQueue::Consumer.new(topic: topic, channel: channel)

      expect { consumer.connection }.to raise_error(InvalidParameterError)
    end
  end

  describe '#terminate' do
    describe 'when using the real queue', fake_queue: false do
      it 'closes the connection' do
        consumer = double('Consumer', connection: nil, terminate: nil)
        allow(Nsq::Consumer).to receive(:new).and_return(consumer)
        topic = 'death_star'
        channel = 'star_killer_base'
        params = { topic: topic, channel: channel }

        live_consumer = MessageQueue::Consumer.new(params)
        live_consumer.connection
        live_consumer.terminate

        expect(consumer).to have_received(:terminate)
      end
    end

    describe 'when using the fake queue', fake_queue: true do
      it 'closes the connection' do
        consumer = double('Consumer', connection: nil, terminate: nil)
        allow(FakeMessageQueue::Consumer).to receive(:new).and_return(consumer)
        topic = 'death_star'
        channel = 'star_killer_base'
        params = { topic: topic, channel: channel }

        live_consumer = MessageQueue::Consumer.new(params)
        live_consumer.connection
        live_consumer.terminate

        expect(consumer).to have_received(:terminate)
      end
    end
  end
end
