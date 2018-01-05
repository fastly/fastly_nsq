# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FastlyNsq::Feeder do
  describe '#push' do
    it 'sends message to processor with the specified priority' do
      messages = []
      processor = ->(m) { messages << m }
      priority = 5
      message = 'foo'

      feeder = described_class.new(processor, priority)

      expect(FastlyNsq.manager.pool).to receive(:post).with(priority).and_call_original

      feeder.push(message)

      expect { messages }.to eventually(contain_exactly(message)).within(2)
    end
  end
end
