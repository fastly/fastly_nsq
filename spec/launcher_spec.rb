# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FastlyNsq::Launcher do
  let!(:channel)  { 'fnsq' }
  let!(:options)  { { max_threads: 3, timeout: 9 } }
  let!(:topic)    { 'fnsq' }

  let(:launcher) { FastlyNsq::Launcher.new options }
  let(:listener)  { FastlyNsq::Listener.new(topic: topic, channel: channel, processor: ->(*) {}) }
  let(:manager) { launcher.manager }

  before { reset_topic(topic, channel: channel) }
  before { expect { listener }.to eventually(be_connected).within(5) }
  after  { listener.terminate if listener.connected? }

  it 'creates a manager with correct options' do
    launcher

    expect(FastlyNsq.manager.pool.max_threads).to eq(3)
  end

  describe '#beat' do
    let!(:logger)   { Logger.new(nil).tap { |l| l.level = Logger::DEBUG } }
    let!(:launcher) { FastlyNsq::Launcher.new pulse: 0.01, logger: logger }

    it 'creates a heartbeat thread' do
      expect(logger).not_to receive(:error)
      expect { launcher.beat }.to eventually_not(eq('dead')).pause_for(1)
    end
  end

  describe '#stop_listeners' do
    before { launcher }

    it 'stops listeners and sets done' do
      expect(launcher).not_to be_stopping
      expect(manager).to receive(:stop_listeners)
      expect(manager).not_to receive(:terminate)

      launcher.stop_listeners

      expect(launcher).to be_stopping
    end
  end

  describe '#stop' do
    before { launcher }

    it 'stops the manager within a deadline' do
      expect(manager).to receive(:terminate).with(options[:timeout])
      launcher.stop
    end
  end

  describe 'callbacks' do
    before { FastlyNsq.events.each { |(_, v)| v.clear } }
    after  { FastlyNsq.events.each { |(_, v)| v.clear } }

    it 'fires :startup event on initialization' do
      obj = spy
      block = -> { obj.start }
      FastlyNsq.on(:startup, &block)

      launcher
      expect(obj).to have_received(:start)
    end

    it 'fires :shutdown event on #stop' do
      launcher

      obj = spy
      block = -> { obj.stop }
      FastlyNsq.on(:shutdown, &block)

      launcher.stop
      expect(obj).to have_received(:stop)
    end

    it 'fires :heartbeat event on #heartbeat' do
      obj = spy
      block = -> { obj.beat }
      FastlyNsq.on(:heartbeat, &block)
      launcher.beat

      expect { obj }.to eventually(have_received(:beat).at_least(:once)).within(0.5)
    end
  end
end
