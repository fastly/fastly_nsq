require 'spec_helper'

RSpec.describe FastlyNsq::Consumer do
  let(:channel)  { 'star_killer_base' }
  let(:topic)    { 'death_star' }
  let(:consumer) { FastlyNsq::Consumer.new topic: topic, channel: channel }

  describe 'when connected to a backend Consumer' do
    let(:backend)   { instance_double FastlyNsq::FakeBackend::Consumer, pop: nil, pop_without_blocking: nil, size: nil, terminate: nil, connected?: true }
    let(:connector) { double 'Connector strategy', new: backend }

    let(:consumer) do
      FastlyNsq::Consumer.new topic: topic, channel: channel, connector: connector
    end

    it 'forwards #pop' do
      expect(backend).to receive(:pop)
      consumer.pop
    end

    it 'forwards #pop_without_blocking' do
      expect(backend).to receive(:pop_without_blocking)
      consumer.pop_without_blocking
    end

    it 'forwards #size' do
      expect(backend).to receive(:size)
      consumer.size
    end

    it 'forwards #terminate' do
      expect(backend).to receive(:terminate)
      consumer.terminate
    end
  end

  describe 'using strategy to determine the consumer' do
    module TestStrategy
      module Consumer
        @@never_terminated = true

        module_function

        def new(*_)
          self
        end

        def connected?
          true
        end

        def terminate
          raise 'Already terminated once' unless @@never_terminated
          @@never_terminated = false
        end

        def was_terminated
          !@@never_terminated
        end
      end
    end

    before do
      allow(FastlyNsq).to receive(:strategy).and_return(TestStrategy)
    end

    it 'instantiates a consumer via Strategy' do
      consumer.terminate
      expect(TestStrategy::Consumer.was_terminated).to be_truthy
    end
  end
end
