require 'spec_helper'

RSpec.describe MessageQueue::Listener do
  describe '#process_next_message' do
    it 'pass the topic and channel to the consumer' do
      allow(SampleMessageProcessor).to receive_message_chain(:new, :go)
      allow(MessageQueue::Consumer).to receive_message_chain(
        :new,
        :connection,
        :pop,
      )
      topic = 'minitest'
      channel = 'northstar'

      MessageQueue::Listener.new(topic: topic, channel: channel).
        process_next_message

      expect(MessageQueue::Consumer).to have_received(:new).
        with(topic: topic, channel: channel)
    end

    it 'processes the message' do
      process_message = double(go: nil)
      allow(MessageProcessor).to receive(:new).and_return(process_message)
      message = double
      allow(MessageQueue::Consumer).to receive_message_chain(
        :new,
        :connection,
        pop: message
      )
      topic = 'minitest'
      channel = 'northstar'

      MessageQueue::Listener.new(topic: topic, channel: channel).
        process_next_message

      expect(MessageProcessor).to have_received(:new).with(message)
      expect(process_message).to have_received(:go)
    end
  end

  describe '#go' do
    # Infinite loops are untestable
  end
end
