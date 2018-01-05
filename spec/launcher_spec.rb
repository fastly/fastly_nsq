# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FastlyNsq::Launcher do
  let!(:options)  { { max_threads: 3, timeout: 9 } }
  let!(:launcher) { FastlyNsq::Launcher.new options }
  let!(:topic)    { 'fnsq' }
  let!(:channel)  { 'fnsq' }
  let(:listener)  { FastlyNsq::Listener.new(topic: topic, channel: channel, processor: ->(*) {}) }

  before { reset_topic(topic, channel: channel) }
  before { expect { listener }.to eventually(be_connected).within(5) }
  after  { listener.terminate if listener.connected? }

  let(:manager) { launcher.manager }

  it 'creates a manager with correct options' do
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
    it 'stops listeners and sets done' do
      expect(launcher).not_to be_stopping
      expect(manager).to receive(:stop_listeners)
      expect(manager).not_to receive(:terminate)

      launcher.stop_listeners

      expect(launcher).to be_stopping
    end
  end

  describe '#stop' do
    it 'stops the manager within a deadline' do
      expect(manager).to receive(:terminate).with(options[:timeout])
      launcher.stop
    end
  end
end
