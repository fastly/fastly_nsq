require 'nsq'
require 'fastly_nsq/consumer'
require 'fastly_nsq/fake_backend'
require 'fastly_nsq/listener'
require 'fastly_nsq/message'
require 'fastly_nsq/producer'
require 'fastly_nsq/strategy'
require 'fastly_nsq/ssl_context'
require 'fastly_nsq/version'

module FastlyNsq
  def self.logger=(logger)
    strategy.logger = logger
  end

  def self.logger
    strategy.logger
  end

  def self.strategy
    Strategy.for_queue
  end
end
