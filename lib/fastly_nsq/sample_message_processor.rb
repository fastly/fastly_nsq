class HeartbeatWorker
  def self.perform_async(_data)
    # noop
  end
end

class UnknownMessageWorker
  def self.perform_async(_data)
    # noop
  end
end

class SampleMessageProcessor
  EVENT_TYPE_TO_WORKER_MAP = {
    'heartbeat' => HeartbeatWorker,
  }.freeze

  def initialize(message_body)
    @message_body = message_body
  end

  def go
    process_message_body
  end

  private

  attr_reader :message_body

  def process_message_body
    message_processor.perform_async(message_data)
  end

  def message_processor
    EVENT_TYPE_TO_WORKER_MAP.fetch(event_type, UnknownMessageWorker)
  end

  def event_type
    parsed_message_body['event_type']
  end

  def message_data
    parsed_message_body['data']
  end

  def parsed_message_body
    JSON.parse(message_body)
  end
end
