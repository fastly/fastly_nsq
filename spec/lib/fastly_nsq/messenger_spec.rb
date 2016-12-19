
require 'spec_helper'
require 'json'

RSpec.describe FastlyNsq::Messenger do
  let(:message)  { { sample: 'sample', message: 'message' } }
  let(:producer) { double 'FastlyNsq::Producer', write: nil, terminate: :terminated }
  let(:origin)   { 'originating_service' }

  let(:expected_attributes) do
    {
      data: {
        sample: 'sample',
        message: 'message',
      },
      meta: {
        originating_service: 'originating_service',
      },
    }.to_json
  end

  subject { FastlyNsq::Messenger }



  describe '#deliver' do
    it 'writes a single message on a producer' do
      subject.producers['topic'] = producer

      subject.deliver message: message, on_topic: 'topic', originating_service: origin

      expect(producer).to have_received(:write).with(expected_attributes)
    end
  end

  describe '#producer_for' do
    it 'returns an FastlyNsq::Producer for the given topic' do
      my_producer = subject.producer_for(topic: 'my_topic')
      expect(my_producer).to be_a(FastlyNsq::Producer)
    end

    it 'persists producers' do
      subject.instance_variable_get(:@producers)['topic'] = producer

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
