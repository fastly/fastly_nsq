require 'spec_helper'

RSpec.describe MessageQueue::Consumer do
  describe '#connection' do
    describe 'when using the real queue' do
      it 'returns an instance of the queue consumer' do
        MessageQueue::FALSY_VALUES.each do |no|
          allow(ENV).to receive(:[]).with('FAKE_QUEUE').and_return(no)
          allow(Nsq::Consumer).to receive(:new)
          topic = 'death_star'
          channel = 'star_killer_base'

          MessageQueue::Consumer.new(topic: topic, channel: channel).connection

          expect(Nsq::Consumer).to have_received(:new).
            with(
              nsqlookupd: ENV.fetch('NSQLOOKUPD_HTTP_ADDRESS'),
              topic: topic,
              channel: channel,
          ).at_least(:once)
        end
      end
    end
  end

  describe 'when using the fake queue' do
    it 'returns an instance of the queue consumer' do
      MessageQueue::TRUTHY_VALUES.each do |yes|
        allow(ENV).to receive(:[]).with('FAKE_QUEUE').and_return(yes)
        allow(FakeMessageQueue::Consumer).to receive(:new)
        topic = 'death_star'
        channel = 'star_killer_base'

        MessageQueue::Consumer.new(topic: topic, channel: channel).connection

        expect(FakeMessageQueue::Consumer).to have_received(:new).
          with(
            nsqlookupd: ENV.fetch('NSQLOOKUPD_HTTP_ADDRESS'),
            topic: topic,
            channel: channel,
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

      expect{ consumer.connection }.to raise_error(InvalidParameterError)
    end
  end
end
