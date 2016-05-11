require 'spec_helper'

RSpec.describe MessageQueue::Producer do
  let(:topic)    { 'death_star' }
  let(:producer) { MessageQueue::Producer.new(topic: topic) }
  let(:backend)  { double 'Producer' }

  describe 'when the ENV is set incorrectly' do
    it 'raises with a helpful error' do
      allow(ENV).to receive(:[]).with('FAKE_QUEUE').and_return('taco')

      expect { producer.terminate }.to raise_error(InvalidParameterError)
    end
  end

  describe 'when connector connects to a backend Producer' do
    let(:producer) do
      MessageQueue::Producer.new topic: topic do
        backend
      end
    end

    it 'forwards #write' do
      expect(backend).to receive(:write).with("it's a message")
      producer.write "it's a message"
    end

    it 'forwards #terminate' do
      expect(backend).to receive(:terminate)
      producer.terminate
    end
  end

  describe 'using the default connector' do
    module TestStrategy
      module Producer
        def self.new(*_); end
      end
    end

    before do
      allow(Strategy).to receive(:for_queue).and_return(TestStrategy)
    end

    it 'instantiates a producer via Strategy' do
      allow(backend).to receive(:terminate)
      expect(TestStrategy::Producer).to receive(:new).and_return(backend)
      producer.terminate
    end
  end
end
