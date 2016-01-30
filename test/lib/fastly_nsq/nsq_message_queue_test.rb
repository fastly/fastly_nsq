require 'test_helper'

describe NsqMessageQueue do
  describe '.producer' do
    it 'creates an instance of the producer' do
      allow(Nsq::Producer).to receive(:new)
      topic = 'minitest'

      NsqMessageQueue.producer(topic: topic)

      expect(Nsq::Producer).to have_received(:new).
        with(
          nsqd: ENV.fetch('NSQD_TCP_ADDRESS'),
          topic: topic,
      )
    end
  end

  describe '.consumer' do
    it 'creates an instance of the consumer' do
      allow(Nsq::Consumer).to receive(:new)
      topic = 'minitest'
      channel = 'william'

      NsqMessageQueue.consumer(topic: topic, channel: channel)

      expect(Nsq::Consumer).to have_received(:new).
        with(
          nsqlookupd: ENV.fetch('NSQLOOKUPD_HTTP_ADDRESS'),
          topic: topic,
          channel: channel,
        )
    end
  end
end
