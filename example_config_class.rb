# frozen_string_literal: true
class ThingWorker
  def self.process(message)
    FastlyNsq.logger.info("IN PROCESS: #{message}")
  end
end

FastlyNsq.configure do |config|
  config.channel      = 'william'
  #config.preprocessor = ->(message) { FastlyNsq.logger.info 'PREPROCESSESES' }

  config.listen_to do |topics|
    topics.add('assign_supplemental_plans', ThingWorker)
  end
end
