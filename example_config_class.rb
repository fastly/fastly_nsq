# frozen_string_literal: true

class MessageProcessor
  def self.process(message)
    FastlyNsq.logger.info("IN PROCESS: #{message}")

    # Do Soemthing with message
  end
end

FastlyNsq.configure do |config|
  config.channel = 'my_channel'
  config.logger = Logger.new
  config.preprocessor = ->(_) { FastlyNsq.logger.info 'PREPROCESSESES' }

  config.listener_config do |lc|
    lc.add_topic('some_topic', MessageProcessor)
    lc.add_topic('some_other_topic', MessageProcessor)
  end
end
