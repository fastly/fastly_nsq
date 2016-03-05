require 'spec_helper'

RSpec.describe MessageQueue::Listener do
  describe '#process_next_message' do
    it 'pass the topic and channel to the consumer' do
      allow(SampleMessageProcessor).to receive_message_chain(:new, :go)
      message = double('Message', finish: nil, body: nil)
      connection = double('Connection', pop: message, terminate: nil)
      consumer = double('Consumer', connection: connection)
      allow(MessageQueue::Consumer).to receive(:new).and_return(consumer)
      topic = 'testing_topic'
      channel = 'testing_channel'

      MessageQueue::Listener.new(topic: topic, channel: channel).
        process_next_message

      expect(MessageQueue::Consumer).to have_received(:new).
        with(topic: topic, channel: channel)
    end

    it 'processes the message' do
      process_message = double(go: nil)
      allow(MessageProcessor).to receive(:new).and_return(process_message)
      message_body = { data: 'value'  }.to_json
      message = double('Message', finish: nil, body: message_body)
      connection = double('Connection', pop: message, terminate: nil)
      consumer = double('Consumer', connection: connection)
      allow(MessageQueue::Consumer).to receive(:new).and_return(consumer)
      topic = 'testing_topic'
      channel = 'testing_channel'

      MessageQueue::Listener.new(topic: topic, channel: channel).
        process_next_message

      expect(MessageProcessor).to have_received(:new).with(message_body)
      expect(process_message).to have_received(:go)
    end

    it 'finishes the message' do
      allow(SampleMessageProcessor).to receive_message_chain(:new, :go)
      message = double('Message', finish: nil, body: nil)
      connection = double('Connection', pop: message, terminate: nil)
      consumer = double('Consumer', connection: connection)
      allow(MessageQueue::Consumer).to receive(:new).and_return(consumer)
      topic = 'testing_topic'
      channel = 'testing_channel'

      MessageQueue::Listener.new(topic: topic, channel: channel).
        process_next_message

      expect(message).to have_received(:finish)
    end

    context 'when using the fake queue and it is empty' do
      it 'offers a helpful exception message' do
        MessageQueue::TRUTHY_VALUES.each do |yes|
          allow(ENV).to receive(:[]).with('FAKE_QUEUE').and_return(yes)
          topic = 'testing_topic'
          channel = 'testing_channel'

          expect {
            MessageQueue::Listener.new(topic: topic, channel: channel).
            process_next_message
          }.to raise_error(EmptyFakeQueueError, /fake queue with no messages/)
        end
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
        topic = 'testing_topic'
        channel = 'testing_channel'

        pid = fork do
          MessageQueue::Listener.new(topic: topic, channel: channel).go
        end

        Process.kill('TERM', pid)

        # Success for this test is to expect it to complete
        # Note: We are not testing the SIGINT case because it orphans the test
        # Ruby process and is sort of meaningless as a test.
      end
    end
  end
end
