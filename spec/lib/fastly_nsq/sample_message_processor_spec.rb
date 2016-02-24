require 'spec_helper'

RSpec.describe SampleMessageProcessor do
  describe '#start' do
    it 'enqueues the appropriate message processor' do
      data =  { 'key' => 'value' }
      message_body = { 'event_type' => 'heartbeat', 'data' => data }.to_json
      allow(HeartbeatWorker).to receive(:perform_async)

      SampleMessageProcessor.new(message_body).go

      expect(HeartbeatWorker).to have_received(:perform_async).with(data)
    end

    describe 'when the message event_type is not known' do
      it 'uses the null object processor' do
        data = { 'sample_key' => 'sample value' }
        message_body = {
          'event_type' => 'unregistered_message_type',
          'data' => data,
        }.to_json
        allow(UnknownMessageWorker).to receive(:perform_async)

        SampleMessageProcessor.new(message_body).go

        expect(UnknownMessageWorker).to have_received(:perform_async).with(data)
      end
    end

    describe 'when the message lacks an event_type' do
      it 'uses the null object processor' do
        data = { 'sample_key' => 'sample value' }
        message_body = {
          'not_the_event_type_key' => 'unregistered_message_type',
          'data' => data,
        }.to_json
        allow(UnknownMessageWorker).to receive(:perform_async)

        SampleMessageProcessor.new(message_body).go

        expect(UnknownMessageWorker).to have_received(:perform_async).with(data)
      end
    end
  end
end
