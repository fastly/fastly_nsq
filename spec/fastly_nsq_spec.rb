# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FastlyNsq do
  describe '#configure' do
    specify { expect { |b| described_class.configure(&b) }.to yield_with_args(described_class) }
  end

  describe '#listen' do
    let!(:default_channel) { subject.channel }
    let!(:topic) { 'fnsq' }

    before { subject.channel = 'fnsq' }
    after { subject.channel = default_channel }

    it 'creates a listener' do
      expect { subject.listen topic, ->(*) {} }.to change { subject.manager.topics }.to([topic])
    end

    it 'creates a listener with a specific priority' do
      listener = subject.listen topic, ->(*) {}, priority: 10
      expect(listener.priority).to eq(10)
    end
  end

  describe '#channel=' do
    let!(:default_channel) { subject.channel }
    after { subject.channel = default_channel }

    it 'allows the channel to be set and retrieved' do
      expect(subject.channel).to be_nil
      subject.channel = 'foo'
      expect(subject.channel).to eq('foo')
    end
  end

  describe '#logger' do
    let!(:default_logger) { subject.logger }
    after { subject.logger = default_logger }

    it 'returns the set logger' do
      logger = Logger.new(nil)
      subject.logger = logger

      expect(subject.logger).to eq logger
    end

    it 'sets the default logger if none is set' do
      subject.instance_variable_set(:@logger, nil)
      expect(subject.instance_variable_get(:@logger)).to be nil
      logger = subject.logger

      expect(logger).to be_instance_of(Logger)
      expect(logger.instance_variable_get(:@logdev).dev).to eq(STDERR)
      expect(logger).to eq(Nsq.logger)
    end
  end

  describe '#logger=' do
    let!(:default_logger) { subject.logger }
    after { subject.logger = default_logger }

    it 'allows the logger to be set and retrieved' do
      logger = Logger.new(STDOUT)
      subject.logger = logger

      expect(subject.logger).to eq logger
    end

    it 'sets Nsq.logger' do
      logger = Logger.new(STDOUT)
      subject.logger = logger

      expect(Nsq.logger).to eq logger
    end
  end

  describe '#manager' do
    it 'represents the active default manager' do
      expect(subject.manager).not_to be_stopped
    end
  end

  describe '#manager=' do
    it 'transfers to specified manager' do
      old_manager = subject.manager
      new_manager = FastlyNsq::Manager.new

      expect(old_manager).to receive(:transfer).with(new_manager)

      subject.manager = new_manager
    end
  end

  describe '#lookupd_http_addresses' do
    it 'retreives NSQLOOKUPD_HTTP_ADDRESS' do
      expect(subject.lookupd_http_addresses).to eq(ENV['NSQLOOKUPD_HTTP_ADDRESS'].split(','))
    end
  end

  describe '#on' do
    before { FastlyNsq.events.each { |(_, v)| v.clear } }
    after  { FastlyNsq.events.each { |(_, v)| v.clear } }

    it 'registers callbacks for events' do
      %i[startup shutdown heartbeat].each do |event|
        block = -> {}
        FastlyNsq.on(event, &block)
        expect(FastlyNsq.events[event]).to eq([block])
      end
    end

    it 'limits callback registration to valid events' do
      expect { FastlyNsq.on(:foo, &-> {}) }.to raise_error(ArgumentError, /Invalid event name/)
    end
  end
end
