# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FastlyNsq do
  describe '#logger=' do
    let!(:default_logger) { FastlyNsq.logger }

    after { FastlyNsq.logger = default_logger }
    it 'allows the logger to be set and retrieved' do
      logger = Logger.new(STDOUT)
      FastlyNsq.logger = logger

      expect(FastlyNsq.logger).to eq logger
    end
  end

  describe '#manager' do
    it 'represents the active default manager' do
      expect(FastlyNsq.manager).not_to be_stopped
    end
  end

  describe '#manager=' do
    it 'transfers to specified manager' do
      old_manager = FastlyNsq.manager
      new_manager = FastlyNsq::Manager.new

      expect(old_manager).to receive(:transfer).with(new_manager)

      FastlyNsq.manager = new_manager
    end
  end

  describe '#lookupd_http_addresses' do
    it 'retreives NSQLOOKUPD_HTTP_ADDRESS' do
      expect(subject.lookupd_http_addresses).to eq(ENV['NSQLOOKUPD_HTTP_ADDRESS'].split(','))
    end
  end
end
