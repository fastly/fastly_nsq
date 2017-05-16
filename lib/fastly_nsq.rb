require 'nsq'
require 'fastly_nsq/consumer'
require 'fastly_nsq/fake_backend'
require 'fastly_nsq/listener'
require 'fastly_nsq/message'
require 'fastly_nsq/messenger'
require 'fastly_nsq/producer'
require 'fastly_nsq/strategy'
require 'fastly_nsq/tls_options'
require 'fastly_nsq/version'

module FastlyNsq
  module_function

  def channel=(channel)
    @channel ||= channel
  end

  def logger=(logger)
    strategy.logger = logger
  end

  def self.preprocessor=(preprocessor)
    @preprocessor ||= preprocessor
  end

  def channel
    @channel
  end

  def logger
    strategy.logger
  end

  def self.preprocessor
    @preprocessor
  end

  def strategy
    Strategy.for_queue
  end

  def configure
    yield self if defined?(FastlyNsq::CLI)
  end

  def listeners
    @listener_config.listeners
  end

  def listen_to
    @listener_config ||= FastlyNsq::Listener::Config.new
    yield @listener_config if block_given?
    @listener_config
  end
end
