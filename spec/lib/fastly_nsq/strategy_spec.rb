require 'spec_helper'

RSpec.describe FastlyNsq::Strategy do
  describe 'when FAKE_QUEUE is falsy' do
    it 'returns the strategy based on the ENV variable' do
      [false, 0, '0', 'false', 'FALSE', 'off', 'OFF', nil].each do |no|
        allow(ENV).to receive(:[]).with('FAKE_QUEUE').and_return(no)

        strategy = FastlyNsq::Strategy.for_queue

        expect(strategy).to eq Nsq
      end
    end
  end

  describe 'when FAKE_QUEUE is truthy' do
    it 'returns the strategy based on the ENV variable' do
      [true, 1, '1', 'true', 'TRUE', 'on', 'ON'].each do |yes|
        allow(ENV).to receive(:[]).with('FAKE_QUEUE').and_return(yes)

        strategy = FastlyNsq::Strategy.for_queue

        expect(strategy).to eq FastlyNsq::FakeBackend
      end
    end
  end

  describe 'when the ENV is set incorrectly' do
    it 'raises with a helpful error' do
      allow(ENV).to receive(:[]).with('FAKE_QUEUE').and_return('taco')

      expect { FastlyNsq::Strategy.for_queue }.to \
        raise_error(FastlyNsq::Strategy::InvalidParameterError)
    end
  end
end
