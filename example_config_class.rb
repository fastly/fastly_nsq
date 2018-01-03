# frozen_string_literal: true

class MessageProcessor
  def self.call(message)
    FastlyNsq.logger.info("IN PROCESS: #{message}")

    # Do Soemthing with message
  end
end

FastlyNsq.configure do |config|
  config.channel = 'my_channel'
  config.logger = Logger.new
  config.preprocessor = ->(_) { FastlyNsq.logger.info 'PREPROCESSESES' }

  lc.listen('some_topic', MessageProcessor)
  lc.listen('some_other_topic', MessageProcessor, priority: 7)
end
