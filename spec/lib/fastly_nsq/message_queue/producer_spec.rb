require 'spec_helper'

RSpec.describe MessageQueue::Producer do
  let(:topic) { 'death_star' }
  let(:producer) { MessageQueue::Producer.new(topic: topic) }

  def fake_producer
    double 'Producer', connection: nil, terminate: nil, write: :written
  end

  describe 'when the ENV is set incorrectly' do
    it 'raises with a helpful error' do
      allow(ENV).to receive(:[]).with('FAKE_QUEUE').and_return('taco')

      expect { producer.terminate }.to raise_error(InvalidParameterError)
    end
  end

  describe 'when using the real queue', fake_queue: false do
    before(:example) do
      @fake_producer = fake_producer
      allow(Nsq::Producer).to receive(:new).and_return(@fake_producer)
    end

    it 'forwards #terminate to Nsq::Producer' do
      producer.terminate
      expect(@fake_producer).to have_received(:terminate)
    end

    it 'forwards #write to Nsq::Producer' do
      producer.write
      expect(@fake_producer).to have_received(:write)
    end
  end

  describe 'when using the fake queue', fake_queue: true do
    before(:example) do
      @fake_producer = fake_producer
      allow(FakeMessageQueue::Producer).to receive(:new).and_return(@fake_producer)
    end

    it 'forwards #terminate to the FakeMessageQueue::Producer' do
      producer.terminate
      expect(@fake_producer).to have_received(:terminate)
    end

    it 'forwards #write to FakeMessageQueue::Producer' do
      producer.write
      expect(@fake_producer).to have_received(:write)
    end
  end
end
