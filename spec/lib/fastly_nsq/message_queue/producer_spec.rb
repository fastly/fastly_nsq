require 'spec_helper'

RSpec.describe MessageQueue::Producer do
  describe '#connection' do
    describe 'when using the real queue' do
      it 'returns an instance of the queue producer' do
        MessageQueue::FALSY_VALUES.each do |no|
          allow(ENV).to receive(:[]).with('FAKE_QUEUE').and_return(no)
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
    end
  end

  describe 'when using the fake queue' do
    it 'returns an instance of the queue producer' do
      MessageQueue::TRUTHY_VALUES.each do |yes|
        allow(ENV).to receive(:[]).with('FAKE_QUEUE').and_return(yes)
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
  end

  describe 'when the ENV is set incorrectly' do
    it 'raises with a helpful error' do
      allow(ENV).to receive(:[]).with('FAKE_QUEUE').and_return('taco')
      topic = 'death_star'

      producer = MessageQueue::Producer.new(topic: topic)

      expect{ producer.connection }.to raise_error(InvalidParameterError)
    end
  end
end
