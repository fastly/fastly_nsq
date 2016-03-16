require 'spec_helper'

RSpec.describe SampleMessageProcessor do
  describe '.topics' do
    it 'specifies the array of topics to listen to' do
      topics = SampleMessageProcessor.topics

      expect(topics).to be_an Array
      expect(topics.first).to be_a String
    end
  end

  describe '#go' do
    it 'enqueues the appropriate message processor' do
      data = { 'key' => 'value' }
      message_body = { 'data' => data }.to_json
      allow(HeartbeatWorker).to receive(:perform_async)
      topic = 'heartbeat'

      SampleMessageProcessor.new(message_body: message_body, topic: topic).go

      expect(HeartbeatWorker).to have_received(:perform_async).with(data)
    end

    describe 'when the message topic is not known' do
      it 'uses the null object processor' do
        data = { 'sample_key' => 'sample value' }
        message_body = { 'data' => data }.to_json
        allow(UnknownMessageWorker).to receive(:perform_async)
        topic = 'unknown_topic'

        SampleMessageProcessor.new(message_body: message_body, topic: topic).go

        expect(UnknownMessageWorker).to have_received(:perform_async).with(data)
      end
    end
  end
end
