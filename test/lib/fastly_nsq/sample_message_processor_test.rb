require 'test_helper'

describe SampleMessageProcessor do
  describe '#start' do
    it 'enqueues the appropriate message processor' do
      data =  { 'key' => 'value' }
      body = { 'event_type' => 'heartbeat', 'data' => data }.to_json
      message = double('Message', body: body, finish: nil)
      allow(HeartbeatWorker).to receive(:perform_async)

      SampleMessageProcessor.new(message).go

      expect(HeartbeatWorker).to have_received(:perform_async).with(data)
    end

    it 'finishes the message' do
      data =  { 'key' => 'value' }
      body = { 'event_type' => 'heartbeat', 'data' => data }.to_json
      message = double('Message', body: body, finish: nil)
      allow(HeartbeatWorker).to receive(:perform_async)

      SampleMessageProcessor.new(message).go

      expect(message).to have_received(:finish)
    end

    describe 'when the message event_type is not known' do
      it 'uses the null object processor' do
        data = { 'sample_key' => 'sample value' }
        body = {
          'event_type' => 'unregistered_message_type',
          'data' => data,
        }.to_json
        message = double('Message', body: body, finish: nil)
        allow(UnknownMessageWorker).to receive(:perform_async)

        SampleMessageProcessor.new(message).go

        expect(UnknownMessageWorker).to have_received(:perform_async).with(data)
      end
    end

    describe 'when the message lacks an event_type' do
      it 'uses the null object processor' do
        data = { 'sample_key' => 'sample value' }
        body = {
          'not_the_event_type_key' => 'unregistered_message_type',
          'data' => data,
        }.to_json
        message = double('Message', body: body, finish: nil)
        allow(UnknownMessageWorker).to receive(:perform_async)

        SampleMessageProcessor.new(message).go

        expect(UnknownMessageWorker).to have_received(:perform_async).with(data)
      end
    end
  end
end
