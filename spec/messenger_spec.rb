
# frozen_string_literal: true

require 'spec_helper'
require 'json'

RSpec.describe FastlyNsq::Messenger do
  let(:message)  { { sample: 'sample', message: 'message' } }
  let(:producer) { double 'FastlyNsq::Producer', write: nil, terminate: :terminated }
  let(:origin)   { 'originating_service' }

  let(:expected_attributes) do
    {
      data: message,
      meta: {
        originating_service: 'originating_service',
      },
    }
  end

  subject { FastlyNsq::Messenger }

  before do
    FastlyNsq::Messenger.instance_variable_set(:@producers, nil)
  end

  describe '#deliver' do
    it 'writes a single message on a producer' do
      subject.producers['topic'] = producer

      subject.deliver message: message, topic: 'topic', originating_service: origin

      expect(producer).to have_received(:write).with(expected_attributes.to_json)
    end

    it 'uses a Unknown for the default originating_service' do
      subject.producers['topic'] = producer
      expected_attributes[:meta][:originating_service] = 'Unknown'

      subject.deliver message: message, topic: 'topic'

      expect(producer).to have_received(:write).with(expected_attributes.to_json)
    end

    it 'allows setting arbitrary metadata' do
      meta = { test: 'test' }

      expected_attributes = { data: message, meta: meta.merge(originating_service: origin) }

      subject.producers['topic'] = producer

      subject.deliver message: message, topic: 'topic', meta: meta, originating_service: origin

      expect(producer).to have_received(:write).with(expected_attributes.to_json)
    end

    it 'prevents originating_service from being overwritten by meta' do
      meta = { test: 'test' }

      expected_attributes = { data: message, meta: meta.merge(originating_service: origin) }

      meta[:originating_service] = 'other_service'

      subject.producers['topic'] = producer

      subject.deliver message: message, topic: 'topic', meta: meta, originating_service: origin

      expect(producer).to have_received(:write).with(expected_attributes.to_json)
    end
  end

  describe '#originating_service=' do
    it "set's the default originating service" do
      subject.producers['nanotopic'] = producer
      service = 'nano service'
      subject.originating_service = service
      expected_attributes[:meta][:originating_service] = service

      subject.deliver message: message, topic: 'nanotopic'

      expect(producer).to have_received(:write).with(expected_attributes.to_json)

      # reset
      subject.originating_service = nil
    end
  end

  describe '#producer_for' do
    it 'returns an FastlyNsq::Producer for the given topic' do
      my_producer = subject.producer_for(topic: 'my_topic')
      expect(my_producer).to be_a(FastlyNsq::Producer)
    end

    it 'persists producers' do
      subject.producers['topic'] = producer

      my_producer = subject.producer_for(topic: 'topic')

      expect(my_producer).to eq(producer)
    end
  end

  describe '#terminate_producer' do
    before do
      subject.producers['topic'] = producer
      subject.terminate_producer(topic: 'topic')
    end

    it 'terminates a producer' do
      expect(producer).to have_received(:terminate)
    end

    it 'removes the producer from the persisted producers' do
      expect(subject.producers.key?('topic')).to be(false)
    end
  end

  describe '#terminate_all_producers' do
    let(:producer_2) { double 'FastlyNsq::Producer', write: nil, terminate: :terminated }

    it 'terminates all the producers and resets the hash or producers' do
      subject.producers['topic'] = producer
      subject.producers['topic_2'] = producer_2

      subject.terminate_all_producers

      expect(producer).to have_received(:terminate)
      expect(producer_2).to have_received(:terminate)
      expect(subject.producers).to be_empty
    end
  end
end
