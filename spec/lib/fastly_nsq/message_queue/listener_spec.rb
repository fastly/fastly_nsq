require 'spec_helper'

RSpec.describe MessageQueue::Listener do
  let(:topic)   { 'testing_topic' }
  let(:channel) { 'testing_channel' }

  describe '#process_next_message' do
    it 'pass the topic and channel to the consumer' do
      allow(SampleMessageProcessor).to receive_message_chain(:new, :go)
      message = double('Message', finish: nil, body: nil)
      connection = double('Connection', pop: message, terminate: nil)
      consumer = double('Consumer', connection: connection)
      allow(MessageQueue::Consumer).to receive(:new).and_return(consumer)

      MessageQueue::Listener.new(topic: topic, channel: channel).
        process_next_message

      expect(MessageQueue::Consumer).to have_received(:new).
        with(topic: topic, channel: channel)
    end

    it 'processes the message' do
      process_message = double(go: nil)
      allow(MessageProcessor).to receive(:new).and_return(process_message)
      message_body = { data: 'value' }.to_json
      message = double('Message', finish: nil, body: message_body)
      connection = double('Connection', pop: message, terminate: nil)
      consumer = double('Consumer', connection: connection)
      allow(MessageQueue::Consumer).to receive(:new).and_return(consumer)

      MessageQueue::Listener.new(topic: topic, channel: channel).
        process_next_message

      expect(MessageProcessor).to have_received(:new).
        with(topic: topic, message_body: message_body)
      expect(process_message).to have_received(:go)
    end

    it 'finishes the message' do
      allow(SampleMessageProcessor).to receive_message_chain(:new, :go)
      message = double('Message', finish: nil, body: nil)
      connection = double('Connection', pop: message, terminate: nil)
      consumer = double('Consumer', connection: connection)
      allow(MessageQueue::Consumer).to receive(:new).and_return(consumer)

      MessageQueue::Listener.new(topic: topic, channel: channel).
        process_next_message

      expect(message).to have_received(:finish)
    end

    context 'when using the fake queue and it is empty', fake_queue: true do
      it 'blocks on the process for longer than the check cycle' do
        delay = FakeMessageQueue::Consumer::SECONDS_BETWEEN_QUEUE_CHECKS + 0.1

        expect do
          Timeout.timeout(delay) do
            MessageQueue::Listener.new(topic: topic, channel: channel).
              process_next_message
          end
        end.to raise_error(Timeout::Error)
      end
    end
  end

  describe '#go' do
    describe 'when a SIGTERM is received' do
      it 'closes the consumer connection' do
        allow(SampleMessageProcessor).to receive_message_chain(:new, :go)
        message = double(finish: nil, body: nil)
        connection = double('Connection', pop: message, terminate: nil)
        consumer = double('Consumer', connection: connection)
        allow(MessageQueue::Consumer).to receive(:new).and_return(consumer)

        pid = fork do
          MessageQueue::Listener.new(topic: topic, channel: channel).go
        end

        Process.kill('TERM', pid)

        # Success for this test is to expect it to complete.
        #
        # Additional Note: We are NOT testing the SIGINT case because it
        # orphans the test's Ruby process and is thus meaningless as a test.
      end
    end
  end
end
