require 'spec_helper'

RSpec.describe FastlyNsq::Listener do
  let(:topic)    { 'testing_topic' }
  let(:channel)  { 'testing_channel' }
  let(:consumer) { FastlyNsq::FakeBackend::Consumer.new topic: topic, channel: channel }
  let(:logger)   { double 'Logger', info: nil, debug: nil, error: nil }

  module TestMessageProcessor
    @@messages_processed = []
    Message = Struct.new(:body, :topic) do
      def finish
        @did_finish = true
      end
    end

    def self.process(incoming_message)
      @@messages_processed.push Message.new(incoming_message.to_s)
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

  let(:message)            { TestMessageProcessor::Message.new 'this is message body' }
  let(:messages_processed) { TestMessageProcessor.messages_processed }
  let(:expected_message)   { TestMessageProcessor::Message.new 'this is message body' }
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

  context 'when not passed a manager' do
    it 'creates a blank manager' do
      expect(listener.identity[:manager]).to_not be_nil
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

      expect(logger).to have_received(:info).once.with(/\[NSQ\] Message Received: #{message.body}/)
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

    context 'when running as a thread' do
      let(:manager) { double 'Manager', listener_stopped: nil, listener_killed: nil }
      let(:thread)  { double 'FakeThread', raise: nil, kill: nil, status: 'fake_thread' }
      let(:listener) do
        FastlyNsq::Listener.new topic:     topic,
                                processor: TestMessageProcessor,
                                logger:    logger,
                                consumer:  consumer,
                                manager:   manager
      end

      describe 'shutdown' do
        it 'informs the manager of a shutdown when run once' do
          listener.go run_once: true

          expect(manager).to have_received(:listener_stopped).with(listener)
        end
      end

      before do
        allow(listener).to receive(:safe_thread).and_return(thread)
      end

      it 'starts and provide status' do
        listener.start
        expect(logger).to have_received(:info)
        expect(listener.status).to eq 'fake_thread'
      end

      it 'can describe itself' do
        id = listener.identity
        expect(id[:consumer]).to_not be_nil
        expect(id[:logger]).to be logger
        expect(id[:manager]).to be manager
        expect(id[:preprocessor]).to be_nil
        expect(id[:processor]).to_not be_nil
        expect(id[:topic]).to_not be_nil
      end

      it 'can be cleanly duplicated' do
        new_listener = listener.clean_dup

        expect(listener.identity).to eq new_listener.identity
      end

      it 'can be terminated' do
        listener.start
        state = listener.instance_variable_get(:@done)
        expect(state).to eq false
        listener.terminate

        state = listener.instance_variable_get(:@done)
        expect(logger).to have_received(:info).twice
        expect(state).to eq true
      end

      it 'can be killed' do
        listener.start
        state = listener.instance_variable_get(:@done)
        expect(state).to eq false
        listener.kill

        state = listener.instance_variable_get(:@done)
        expect(logger).to have_received(:info).twice
        expect(thread).to have_received(:raise).with(FastlyNsq::Shutdown)
        expect(state).to eq true
      end
    end
  end
end
