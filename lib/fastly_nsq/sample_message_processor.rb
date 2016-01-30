class HeartbeatWorker; end
class UnknownMessageWorker; end

class SampleMessageProcessor
  EVENT_TYPE_TO_WORKER_MAP = {
    'heartbeat' => HeartbeatWorker,
  }.freeze

  def initialize(message)
    @message = message
  end

  def start
    process_message
    message.finish
  end

  private

  attr_reader :message

  def process_message
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

  def message_body
    message.body
  end
end
