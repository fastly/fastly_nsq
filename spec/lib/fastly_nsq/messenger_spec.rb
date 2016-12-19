
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
      subject.instance_variable_set(:@producers, { 'topic' => producer })

      subject.deliver message: message, on_topic: 'topic', originating_service: origin

      expect(producer).to have_received(:write).with(expected_attributes)
    end
  end
end
