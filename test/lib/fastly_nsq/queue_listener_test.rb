require 'test_helper'

describe QueueListener do
  describe '#process_next_message' do
    it 'will take a passed topic' do
      allow(MessageQueue).to receive_message_chain(
        :new,
        :consumer,
        :pop,
      )
      topic = 'minitest'

      QueueListener.new(topic: topic).process_next_message

      expect(MessageQueue).to have_received(:new).with(topic: topic)
    end

    describe 'when there is a message' do
      it 'processes the message' do
        process_message = double(start: nil)
        allow(MessageProcessor).to receive(:new).and_return(process_message)
        message = double(present?: true)
        allow(MessageQueue).to receive_message_chain(
          :new,
          :consumer,
          pop: message
        )
        topic = 'minitest'

        QueueListener.new(topic: topic).process_next_message

        expect(MessageProcessor).to have_received(:new).with(message)
        expect(process_message).to have_received(:start)
      end
    end

    describe 'when there is no message' do
      it 'does not process the message' do
        missing_message = double(present?: false)
        allow(MessageQueue).to receive_message_chain(
          :new,
          :consumer,
          pop: missing_message
        )
        process_message = double(start: nil)
        allow(MessageProcessor).to receive(:new).and_return(process_message)
        topic = 'minitest'

        QueueListener.new(topic: topic).process_next_message

        expect(MessageProcessor).not_to have_received(:new)
        expect(process_message).not_to have_received(:start)
      end
    end
  end

  describe '#start' do
    # Infinite loops are untestable
  end
end
