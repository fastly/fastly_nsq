# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FastlyNsq::Testing do
  describe '.message' do
    it 'returns a FastlyNsq::Message' do
      data = { 'foo' => 'bar' }
      message = FastlyNsq::Testing.message(data: data)

      expect(message.body).to eq('data' => data, 'meta' => nil)
    end

    it 'returns a FastlyNsq::Message with meta' do
      data = { 'foo' => 'bar' }
      meta = 'foo'
      message = FastlyNsq::Testing.message(data: data, meta: meta)

      expect(message.body).to eq('data' => data, 'meta' => meta)
    end

    it 'wraps a FastlyNsq::TestMessage' do
      data = 'bar'
      message = FastlyNsq::Testing.message(data: data)
      expect(message.nsq_message).to be_a(FastlyNsq::TestMessage)
      expect(message.nsq_message.body).to eq(JSON.dump('data' => data, 'meta' => nil))
    end
  end
end
