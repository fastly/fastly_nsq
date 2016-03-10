require 'spec_helper'

RSpec.describe MessageQueue do
  describe '.logger' do
    describe 'when using the fake queue' do
      it 'allows the logger to be set and retrieved' do
        use_fake_connection do
          logger = Logger.new(STDOUT)
          MessageQueue.logger = logger

          expect(MessageQueue.logger).to eq logger
        end
      end
    end

    describe 'when using the real queue' do
      it 'allows the logger to be set and retrieved' do
        use_real_connection do
          logger = Logger.new(STDOUT)
          MessageQueue.logger = logger

          expect(MessageQueue.logger).to eq logger
        end
      end
    end
  end
end
