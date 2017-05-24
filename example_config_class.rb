# frozen_string_literal: true
class ThingWorker
  def self.process(message)
    FastlyNsq.logger.info("IN PROCESS: #{message}")
  end
end

FastlyNsq.configure do |config|
  config.channel = 'william'
  config.logger = Logger.new
  config.preprocessor = ->(_) { FastlyNsq.logger.info 'PREPROCESSESES' }

  config.listener_config do |lc|
    lc.adld_topic('assign_supplemental_plans', ThingWorker)
  end
end
