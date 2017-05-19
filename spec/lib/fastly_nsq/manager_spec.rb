require 'spec_helper'
require 'fastly_nsq/manager'

RSpec.describe FastlyNsq::Manager do
  class TestProcessor
    def self.process(message)
      FastlyNsq.logger.info("IN PROCESS: #{message}")
    end
  end

  let(:logger)   { double 'Logger', info: nil, debug: nil, error: nil }
  let(:manager)  { FastlyNsq::Manager.new options }
  let(:listener_1) { instance_double 'Listener1', new: nil, start: nil, terminate: nil, kill: nil, clean_dup: listener_dup }
  let(:listener_2) { instance_double 'Listener2', new: nil, start: nil, terminate: nil, kill: nil, clean_dup: listener_dup }
  let(:listener_dup) { instance_double 'ListenerDup', start: nil }
  let(:options)  { { joe: 'biden' } }

  let(:configed_topics) do
    [
      { topic: 'warm_topic', klass: TestProcessor },
      { topic: 'cool_topic', klass: TestProcessor },
    ]
  end

  before do
    FastlyNsq.configure do |config|
      config.channel = 'william'
      config.listen_to do |topics|
        configed_topics.each do |t|
          topics.add(t[:topic], t[:klass])
        end
      end
    end

    allow(FastlyNsq::Listener).to receive(:new).and_return(listener_1, listener_2)
    manager.start
  end

  after do
    FastlyNsq.reset_config
  end

  describe '#start' do
    it 'sets up each configured listener' do
      configed_topics.each do |t|
        expect(FastlyNsq::Listener).to have_received(:new).with({
          topic:        t[:topic],
          channel:      FastlyNsq.channel,
          processor:    t[:klass],
          preprocessor: FastlyNsq.preprocessor,
          manager:      manager,
        })
      end
    end

    it 'starts all listeners' do
      expect(listener_1).to have_received(:start)
      expect(listener_2).to have_received(:start)
    end

    it 'populates @listeners with all created listeners' do
      expect(manager.listeners).to eq Set.new([listener_1, listener_2])
    end
  end

  describe '#quiet' do
    it 'does nothing if stopping' do
      manager.instance_variable_set(:@done, true)
      manager.quiet
      expect(listener_1).to_not have_received(:terminate)
      expect(listener_2).to_not have_received(:terminate)
    end

    it 'terminates all listeners' do
      manager.quiet
      expect(listener_1).to have_received(:terminate)
      expect(listener_2).to have_received(:terminate)
    end
  end

  describe '#stop' do
    it 'does nothing if no listeners exist post quiet' do
      allow(manager).to receive(:quiet)
      allow(manager).to receive(:hard_shutdown)
      manager.instance_variable_set(:@listeners, Set.new)

      manager.stop(Time.now)

      expect(manager).to have_received(:quiet)
      expect(manager).to_not have_received(:hard_shutdown)
    end

    it 'forces shutdown if listeners remain after deadline' do
      allow(manager).to receive(:hard_shutdown).and_call_original

      manager.stop(Time.now)

      expect(manager).to have_received(:hard_shutdown)
      expect(listener_1).to have_received(:kill)
      expect(listener_2).to have_received(:kill)
    end
  end

  describe '#listener_stopped' do
    it 'removes listeners from set of listeners' do
      manager.listener_stopped(listener_1)
      expect(manager.listeners).to eq Set.new([listener_2])
    end
  end

  describe '#listener_killed' do
    it 'removes listeners from set of listeners' do
      manager.quiet # mark for stopping
      manager.listener_killed(listener_1)
      expect(manager.listeners).to eq Set.new([listener_2])
    end

    it 'creates and starts replacements if not stopping' do
      manager.listener_killed(listener_1)
      expect(manager.listeners).to eq Set.new([listener_dup, listener_2])
      expect(listener_dup).to have_received(:start)
    end
  end
end
