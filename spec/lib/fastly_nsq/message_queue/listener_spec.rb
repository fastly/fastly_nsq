require 'spec_helper'

RSpec.describe MessageQueue::Listener do
  let(:topic)    { 'testing_topic' }
  let(:channel)  { 'testing_channel' }
  let(:consumer) { FakeMessageQueue::Consumer.new topic: topic, channel: channel }

  module TestMessageProcessor
    @@messages_processed = []
    Message = Struct.new(:body, :topic) do
      def finish; @did_finish = true; end
    end

    def self.call(body, topic)
      @@messages_processed.push Message.new(body, topic)
    end

    def self.messages_processed
      @@messages_processed
    end

    def self.clear
      @@messages_processed = []
    end
  end

  let(:listener) do
    MessageQueue::Listener.new topic:     topic,
                               channel:   channel,
                               processor: TestMessageProcessor,
                               consumer:  consumer
  end

  let(:message)            { TestMessageProcessor::Message.new 'this is message body', topic }
  let(:messages_processed) { TestMessageProcessor.messages_processed }
  let(:expected_message)   { TestMessageProcessor::Message.new('this is message body', topic) }
  let(:expected_messages)  { [ expected_message ] }

  describe 'instantiating without a consumer' do
    it 'instantiates a consumer, passing the topic and channel' do
      allow(MessageQueue::Consumer).to receive(:new)

      MessageQueue::Listener.new topic:     topic,
                                 channel:   channel,
                                 processor: TestMessageProcessor,
                                 consumer:  nil

      expect(MessageQueue::Consumer).to have_received(:new).
        with(topic: topic, channel: channel)
    end
  end

  describe 'when processing next message' do
    before(:each) { TestMessageProcessor.clear }

    it 'processes the next message' do
      allow(consumer).to receive(:pop).and_return(message)
      listener.process_next_message

      expect(messages_processed).to eql(expected_messages)
    end

    it 'finishes the message' do
      allow(consumer).to receive(:pop).and_return(message)
      allow(message).to receive(:finish)

      listener.process_next_message

      expect(message).to have_received(:finish).once
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
