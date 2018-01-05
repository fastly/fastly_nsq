# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'integration' do
  let!(:topic) { 'fnsq-topic' }
  let!(:channel) { 'fnsq-channel' }
  let!(:message) { { 'foo' => 'bar' } }

  before { reset_topic(topic, channel: channel) }

  it 'processes jobs' do
    received = nil
    producer = FastlyNsq::Producer.new(topic: topic)
    FastlyNsq::Listener.new(topic: topic, channel: channel, processor: ->(m) { received = m })
    producer.write JSON.dump(message)

    expect { received&.body }.to eventually(eq(message)).within(2)
  end

  describe 'inline', :inline do
    it 'processes job' do
      received = nil
      producer = FastlyNsq::Producer.new(topic: topic)
      FastlyNsq::Listener.new(topic: topic, channel: channel, processor: ->(m) { received = m })
      producer.write JSON.dump(message)

      expect(received.body).to eq(message)
    end
  end

  describe 'fake', :fake do
    it 'stores jobs' do
      received = nil
      encoded_message = JSON.dump(message)
      producer = FastlyNsq::Producer.new(topic: topic)
      listener = FastlyNsq::Listener.new(topic: topic, channel: channel, processor: ->(m) { received = m })
      expect { producer.write encoded_message }.to change { listener.messages.size }.by(1)

      queued_message = listener.messages.shift
      expect(queued_message.body).to eq(encoded_message)

      listener.drain

      expect(received.body).to eq(message)
    end
  end
end
