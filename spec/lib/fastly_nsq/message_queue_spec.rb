require 'spec_helper'

RSpec.describe MessageQueue do
  describe '.logger' do
    describe 'when using the fake queue', fake_queue: true do
      it 'allows the logger to be set and retrieved' do
        logger = Logger.new(STDOUT)
        MessageQueue.logger = logger

        expect(MessageQueue.logger).to eq logger
      end
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
