require 'nsq'
require_relative 'fake_message_queue'
require_relative 'message_queue/listener'
require_relative 'message_queue/producer'
require_relative 'message_queue/consumer'
require_relative 'message_queue/strategy'
require_relative 'ssl_context'

module MessageQueue
  FALSY_VALUES = [false, 0, '0', 'false', 'FALSE', 'off', 'OFF', nil].freeze
  TRUTHY_VALUES = [true, 1, '1', 'true', 'TRUE', 'on', 'ON'].freeze

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
