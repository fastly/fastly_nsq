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

  describe '#logger=' do
    let!(:default_logger) { subject.logger }
    after { subject.logger = default_logger }

    it 'allows the logger to be set and retrieved' do
      logger = Logger.new(STDOUT)
      subject.logger = logger

      expect(subject.logger).to eq logger
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
end
