require 'spec_helper'

RSpec.describe MessageQueue::Consumer do
  let(:channel)  { 'star_killer_base' }
  let(:topic)    { 'death_star' }
  let(:consumer) { MessageQueue::Consumer.new(topic: topic, channel: channel) }

  def fake_consumer
    double 'Consumer', connection: nil, terminate: nil, pop: :popped, size: 0
  end

  describe 'when the ENV is set incorrectly' do
    it 'raises with a helpful error' do
      allow(ENV).to receive(:[]).with('FAKE_QUEUE').and_return('taco')

      expect { consumer.terminate }.to raise_error(InvalidParameterError)
    end
  end

  describe 'when using the real queue', fake_queue: false do
    before(:example) do
      @fake_consumer = fake_consumer
      allow(Nsq::Consumer).to receive(:new).and_return(@fake_consumer)
    end

    it 'forwards #pop to Nsq::Consumer' do
      consumer.pop
      expect(@fake_consumer).to have_received(:pop)
    end

    it 'forwards #size to Nsq::Consumer' do
      consumer.size
      expect(@fake_consumer).to have_received(:size)
    end

    it 'forwards #terminate to Nsq::Consumer' do
      consumer.terminate

      expect(@fake_consumer).to have_received(:terminate)
    end
  end

  describe 'when using the fake queue', fake_queue: true do
    before(:example) do
      @fake_consumer = fake_consumer
      allow(FakeMessageQueue::Consumer).to receive(:new).and_return(@fake_consumer)
    end

    it 'forwards #pop to FakeMessageQueue::Consumer' do
      consumer.pop
      expect(@fake_consumer).to have_received(:pop)
    end

    it 'forwards #size to FakeMessageQueue::Consumer' do
      consumer.size
      expect(@fake_consumer).to have_received(:size)
    end

    it 'forwards #terminate to FakeMessageQueue::Consumer' do
      consumer.terminate

      expect(@fake_consumer).to have_received(:terminate)
    end
  end
end
