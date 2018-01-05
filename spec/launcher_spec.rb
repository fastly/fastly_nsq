# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FastlyNsq::Launcher do
  let!(:options)  { { max_threads: 3, timeout: 9 } }
  let!(:launcher) { FastlyNsq::Launcher.new options }

  let(:manager)  { FastlyNsq.manager }
  let(:thread)   { instance_double 'Thread' }

  before do
    allow(launcher).to receive(:safe_thread).and_return(thread)
  end

  it 'creates a manager with correct options' do
    expect(FastlyNsq.manager.pool.max_threads).to eq(3)
  end

  describe '#run' do
    it 'creates a heartbeat thread' do
      launcher.run
      expect(launcher).to have_received(:safe_thread).with('heartbeat')
      expect(launcher.stopping?).to eq false
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
