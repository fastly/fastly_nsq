# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FastlyNsq::Launcher do
  let(:launcher) { FastlyNsq::Launcher.new options }
  let(:manager)  { instance_double 'Manager', start: nil, quiet: nil, stop: nil }
  let(:thread)   { instance_double 'Thread' }
  let(:options)  { { max_threads: 3, timeout: 9 } }

  before do
    allow(FastlyNsq::Manager).to receive(:new).and_return(manager)
    allow(launcher).to receive(:safe_thread).and_return(thread)
  end

  it 'creates a manager with correct options' do
    expect(FastlyNsq::Manager).to have_received(:new).with(max_threads: 3)
  end

  describe '#run' do
    it 'creates a heartbeat thread' do
      launcher.run
      expect(launcher).to have_received(:safe_thread).with('heartbeat')
      expect(launcher.stopping?).to eq false
    end

    it 'starts the setup manager' do
      launcher.run
      expect(manager).to have_received(:start)
      expect(launcher.stopping?).to eq false
    end
  end

  describe '#quiet' do
    it 'quites the manager and sets done' do
      expect(launcher.stopping?).to eq false
      launcher.quiet
      expect(manager).to have_received(:quiet)
      expect(launcher.stopping?).to eq true
    end
  end

  describe '#stop' do
    it 'stops the manager within a deadline' do
      now = Time.now
      allow(Time).to receive(:now).and_return(now)
      launcher.stop
      expect(manager).to have_received(:stop).with(now + options[:timeout])
    end

    it 'quites the manager' do
      launcher.stop
      expect(manager).to have_received(:quiet)
      expect(launcher.stopping?).to eq true
    end
  end
end
