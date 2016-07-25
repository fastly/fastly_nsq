require 'json'

module FastlyNsq
  class Message
    def initialize()
    end

    def message_data
      parsed_message_body['data']
    end

    def parsed_message_body
      JSON.parse(message_body)
    end
  end
end