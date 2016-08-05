require 'spec_helper'

RSpec.describe FastlyNsq::Listener do
  let(:topic)    { 'testing_topic' }
  let(:channel)  { 'testing_channel' }
  let(:consumer) { FastlyNsq::FakeBackend::Consumer.new topic: topic, channel: channel }
  let(:logger)   { double 'Logger', info: nil }

  module TestMessageProcessor
    @@messages_processed = []
    Message = Struct.new(:body, :topic) do
      def finish
        @did_finish = true
      end
    end

    def self.process(incoming_message, topic)
      @@messages_processed.push Message.new(incoming_message.to_s, topic)
    end

    def self.messages_processed
      @@messages_processed
    end

    def self.clear
      @@messages_processed = []
    end
  end

  let(:listener) do
    FastlyNsq::Listener.new topic:     topic,
                            processor: TestMessageProcessor,
                            consumer:  consumer,
                            logger:    logger
  end

  let(:message)            { TestMessageProcessor::Message.new 'this is message body', topic }
  let(:messages_processed) { TestMessageProcessor.messages_processed }
  let(:expected_message)   { TestMessageProcessor::Message.new('this is message body', topic) }
  let(:expected_messages)  { [expected_message] }

  describe 'instantiating without a consumer' do
    it 'instantiates a consumer, passing the topic and channel' do
      allow(FastlyNsq::Consumer).to receive(:new)

      FastlyNsq::Listener.new topic:     topic,
                              channel:   channel,
                              processor: TestMessageProcessor,
                              consumer:  nil

      expect(FastlyNsq::Consumer).to have_received(:new).
        with(topic: topic, channel: channel)
    end
  end

  context 'when using the fake queue and it is empty', fake_queue: true do
    before do
      TestMessageProcessor.clear
      FastlyNsq::FakeBackend.delay = 0.1
    end

    it 'blocks on the process for longer than the check cycle' do
      delay = FastlyNsq::FakeBackend.delay + 0.1

      expect do
        Timeout.timeout(delay) do
          listener.go run_once: true
        end
      end.to raise_error(Timeout::Error)
    end
  end

  describe 'when processing next message' do
    before(:each) do
      TestMessageProcessor.clear
      allow(consumer).to receive(:pop).and_return(message)
    end

    it 'processes the next message' do
      listener.go run_once: true

      expect(messages_processed).to eql(expected_messages)
    end

    it 'finishes the message' do
      allow(message).to receive(:finish)

      listener.go run_once: true

      expect(message).to have_received(:finish).once
    end

    it 'logs info for the message body' do
      allow(logger).to receive(:info)
      listener.go run_once: true

      expect(logger).to have_received(:info).once.with \
        /\[NSQ\] Message Received: #{message.body}/
    end

    context 'when preprocessor is provided' do
      it 'calls the preprocessor' do
        preprocessor_was_called = false
        preprocessor = ->(*_args) { preprocessor_was_called = true }

        listener = FastlyNsq::Listener.new topic:        topic,
                                           processor:    TestMessageProcessor,
                                           consumer:     consumer,
                                           logger:       logger,
                                           preprocessor: preprocessor

        listener.go run_once: true
        expect(preprocessor_was_called).to be_truthy
      end
    end
  end
end
