require 'spec_helper'

RSpec.describe FastlyNsq::SampleMessageProcessor do
  describe '.topics' do
    it 'specifies the array of topics to listen to' do
      topics = FastlyNsq::SampleMessageProcessor.topics

      expect(topics).to be_an Array
      expect(topics.first).to be_a String
    end
  end

  describe '#go' do
    it 'enqueues the appropriate message processor' do
      data = { 'key' => 'value' }
      message_body = { 'data' => data }.to_json
      allow(FastlyNsq::HeartbeatWorker).to receive(:perform_async)
      topic = 'heartbeat'

      FastlyNsq::SampleMessageProcessor.new(message_body: message_body, topic: topic).go

      expect(FastlyNsq::HeartbeatWorker).to have_received(:perform_async).with(data)
    end

    describe 'when the message topic is not known' do
      it 'uses the null object processor' do
        data = { 'sample_key' => 'sample value' }
        message_body = { 'data' => data }.to_json
        allow(FastlyNsq::UnknownMessageWorker).to receive(:perform_async)
        topic = 'unknown_topic'

        FastlyNsq::SampleMessageProcessor.new(message_body: message_body, topic: topic).go

        expect(FastlyNsq::UnknownMessageWorker).to have_received(:perform_async).with(data)
      end
    end
  end
end
