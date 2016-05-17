require 'spec_helper'

RSpec.describe FastlyNsq::Consumer do
  let(:channel)  { 'star_killer_base' }
  let(:topic)    { 'death_star' }
  let(:consumer) { FastlyNsq::Consumer.new topic: topic, channel: channel }
  let(:backend)  { double 'Consumer' }

  describe 'when connector connects to a backend Consumer' do
    let(:consumer) do
      FastlyNsq::Consumer.new topic: topic, channel: channel, connector: ->(_) { backend }
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

  describe 'using the default connector' do
    module TestStrategy
      module Consumer
        def self.new(*_); end
      end
    end

    before do
      allow(FastlyNsq).to receive(:strategy).and_return(TestStrategy)
    end

    it 'instantiates a consumer via Strategy' do
      allow(backend).to receive(:terminate)
      expect(TestStrategy::Consumer).to receive(:new).and_return(backend)
      consumer.terminate
    end
  end
end
