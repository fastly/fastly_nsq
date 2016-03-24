require 'spec_helper'

RSpec.describe Strategy do
  describe '.for_queue' do
    describe 'when using the fake queue', fake_queue: true do
      it 'returns the strategy based on the ENV variable' do
        strategy = Strategy.for_queue

        expect(strategy).to eq FakeMessageQueue
      end
    end

    describe 'when using the real queue', fake_queue: false do
      it 'returns the strategy based on the ENV variable' do
        strategy = Strategy.for_queue

        expect(strategy).to eq Nsq
      end
    end

    describe 'when the ENV is set incorrectly' do
      it 'raises with a helpful error' do
        allow(ENV).to receive(:[]).with('FAKE_QUEUE').and_return('taco')

        expect { Strategy.for_queue }.to raise_error(InvalidParameterError)
      end
    end
  end
end
