
require 'spec_helper'
require 'json'

RSpec.describe FastlyNsq::Messenger do
  let(:message)  { { sample: 'sample', message: 'message' } }
  let(:producer) { double 'FastlyNsq::Producer', write: queue, terminate: :terminated }
  let(:queue)    { double 'Thread::Queue', close: :closed }

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

  subject { FastlyNsq::Messenger.new originating_service: 'originating_service', producer: producer }

  it 'writes a single message on a producer and terminates' do
    subject.deliver message: message, on_topic: 'topic'

    expect(producer).to have_received(:write).with(expected_attributes)
    expect(producer).to have_received(:terminate)
    expect(queue).to    have_received(:close)
  end
end
