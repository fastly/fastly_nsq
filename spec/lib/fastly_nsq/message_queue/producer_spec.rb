require 'spec_helper'

RSpec.describe MessageQueue::Producer do
  describe '#connection' do
    describe 'when using the real queue', fake_queue: false do
      it 'returns an instance of the queue producer' do
        allow(Nsq::Producer).to receive(:new)
        topic = 'death_star'

        MessageQueue::Producer.new(topic: topic).connection

        expect(Nsq::Producer).to have_received(:new).
          with(
            nsqd: ENV.fetch('NSQD_TCP_ADDRESS'),
            topic: topic,
          ).at_least(:once)
      end
    end

    describe 'when using the fake queue', fake_queue: true do
      it 'returns an instance of the queue producer' do
        allow(FakeMessageQueue::Producer).to receive(:new)
        topic = 'death_star'

        MessageQueue::Producer.new(topic: topic).connection

        expect(FakeMessageQueue::Producer).to have_received(:new).
          with(
            nsqd: ENV.fetch('NSQD_TCP_ADDRESS'),
            topic: topic,
          ).at_least(:once)
      end
    end

    describe 'when the ENV is set incorrectly' do
      it 'raises with a helpful error' do
        allow(ENV).to receive(:[]).with('FAKE_QUEUE').and_return('taco')
        topic = 'death_star'

        producer = MessageQueue::Producer.new(topic: topic)

        expect { producer.connection }.to raise_error(InvalidParameterError)
      end
    end
  end

  describe '#terminate' do
    describe 'when using the real queue', fake_queue: false do
      it 'closes the connection' do
        producer = double('Producer', connection: nil, terminate: nil)
        allow(Nsq::Producer).to receive(:new).and_return(producer)
        topic = 'death_star'

        live_producer = MessageQueue::Producer.new(topic: topic)
        live_producer.connection
        live_producer.terminate

        expect(producer).to have_received(:terminate)
      end
    end

    describe 'when using the fake queue', fake_queue: true do
      it 'closes the connection' do
        producer = double('Producer', connection: nil, terminate: nil)
        allow(FakeMessageQueue::Producer).to receive(:new).and_return(producer)
        topic = 'death_star'

        live_producer = MessageQueue::Producer.new(topic: topic)
        live_producer.connection
        live_producer.terminate

        expect(producer).to have_received(:terminate)
      end
    end
  end
end
