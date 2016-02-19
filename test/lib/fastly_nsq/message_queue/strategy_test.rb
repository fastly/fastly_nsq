require 'test_helper'

describe Strategy do
  describe '.for_queue' do
    describe 'when using the fake queue' do
      it 'returns the strategy based on the ENV variable' do
        MessageQueue::TRUTHY_VALUES.each do |yes|
          allow(ENV).to receive(:[]).with('FAKE_QUEUE').and_return(yes)

          strategy = Strategy.for_queue

          assert_equal FakeMessageQueue, strategy
        end
      end
    end

    describe 'when using the real queue' do
      it 'returns the strategy based on the ENV variable' do
        MessageQueue::FALSY_VALUES.each do |no|
          allow(ENV).to receive(:[]).with('FAKE_QUEUE').and_return(no)

          strategy = Strategy.for_queue

          assert_equal Nsq, strategy
        end
      end
    end

    describe 'when the ENV is set incorrectly' do
      it 'raises with a helpful error' do
        allow(ENV).to receive(:[]).with('FAKE_QUEUE').and_return('taco')

        assert_raises(InvalidParameterError) do
          Strategy.for_queue
        end
      end
    end
  end
end
