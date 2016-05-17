module FastlyNsq
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
    TOPIC_TO_WORKER_MAP = {
      'heartbeat' => HeartbeatWorker,
    }.freeze

    def self.topics
      TOPIC_TO_WORKER_MAP.keys
    end

    def initialize(message_body:, topic:)
      @message_body = message_body
      @topic = topic
    end

    def go
      process_message_body
    end

    private

    attr_reader :message_body, :topic

    def process_message_body
      message_processor.perform_async(message_data)
    end

    def message_processor
      TOPIC_TO_WORKER_MAP.fetch(topic, UnknownMessageWorker)
    end

    def message_data
      parsed_message_body['data']
    end

    def parsed_message_body
      JSON.parse(message_body)
    end
  end
end
