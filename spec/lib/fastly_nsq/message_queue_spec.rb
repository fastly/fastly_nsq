require 'spec_helper'

RSpec.describe MessageQueue do
  TestStrategy = Class.new

  it 'allows the logger to be set and retrieved' do
    logger = Logger.new(STDOUT)
    MessageQueue.logger = logger

    expect(MessageQueue.logger).to eq logger
  end

  it 'returns the current Strategy' do
    allow(MessageQueue::Strategy).to receive(:for_queue).and_return(TestStrategy)

    expect(MessageQueue.strategy).to eql(TestStrategy)
  end

  describe '.logger' do
    describe 'when using the fake queue', fake_queue: true do
    end

    describe 'when using the real queue, fake_queue: false' do
      it 'allows the logger to be set and retrieved' do
        logger = Logger.new(STDOUT)
        MessageQueue.logger = logger

        expect(MessageQueue.logger).to eq logger
      end
    end
  end
end
