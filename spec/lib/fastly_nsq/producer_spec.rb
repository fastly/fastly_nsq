require 'spec_helper'

RSpec.describe FastlyNsq::Producer do
  let(:topic)    { 'death_star' }
  let(:producer) { FastlyNsq::Producer.new(topic: topic) }

  describe 'when connector connects to a backend Producer' do
    let(:backend)   { instance_double FastlyNsq::FakeBackend::Producer, write: nil, terminate: nil }
    let(:connector) { double 'Connector', new: backend }
    let(:producer) do
      FastlyNsq::Producer.new topic: topic, connector: connector
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
        @@never_terminated = true

        module_function

        def new(*_)
          self
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

    it 'instantiates a producer via Strategy' do
      producer.terminate
      expect(TestStrategy::Producer.was_terminated).to be_truthy
    end
  end
end
