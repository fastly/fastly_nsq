require 'test_helper'
require 'nsq'

describe MessageQueue do
  describe '#producer' do
    it 'returns a connection to the fake producer with the default topic' do
      allow(FakeMessageQueue).to receive(:producer)
      topic = 'minitest'

      MessageQueue.new(topic: topic).producer

      expect(FakeMessageQueue).to have_received(:producer).with(topic: topic)
    end
  end

  describe '#consumer' do
    it 'returns a connection to the fake consumer' do
      allow(FakeMessageQueue).to receive(:consumer)
      topic = 'minitest'

      MessageQueue.new(topic: topic).consumer

      expect(FakeMessageQueue).to have_received(:consumer).
        with(topic: topic, channel: MessageQueue::CHANNEL)
    end
  end

  describe '#queue' do
    describe 'when in using the live queue' do
      it 'returns the connection to the live server' do
        allow(ENV).to receive(:[]).with('FAKE_QUEUE').and_return(nil)
        topic = 'minitest'

        assert_equal MessageQueue.new(topic: topic).queue, NsqMessageQueue
      end
    end

    describe 'when the FAKE_QUEUE ENV variable is set' do
      it 'returns the connection to the fake queue' do
        allow(ENV).to receive(:[]).with('FAKE_QUEUE').and_return(true)
        topic = 'minitest'

        assert_equal MessageQueue.new(topic: topic).queue, FakeMessageQueue
      end
    end
  end
end
