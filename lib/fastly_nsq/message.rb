# frozen_string_literal: true

require 'json'

##
# Adapter to Nsq::Message. Provides convenience methods for interacting
# with a message. Delegates management methods to the Nsq::Message
class FastlyNsq::Message
  extend Forwardable

  # @!method attempts
  #   Delegated to `self.nsq_message`
  #   @return [Nsq::Message#attempts]
  #   @see https://www.rubydoc.info/gems/nsq-ruby/Nsq/Message#attempts-instance_method
  # @!method touch
  #   Delegated to `self.nsq_message`
  #   @return [Nsq::Message#touch]
  #   @see https://www.rubydoc.info/gems/nsq-ruby/Nsq/Message#touch-instance_method
  # @!method timestamp
  #   Delegated to `self.nsq_message`
  #   @return [Nsq::Message#timestamp]
  #   @see https://www.rubydoc.info/gems/nsq-ruby/Nsq/Message#timestamp-instance_method
  def_delegators :@nsq_message, :attempts, :touch, :timestamp

  # @return [Symbol] Message state. Returns `nil` if message has not been requeued or finished.
  attr_reader :managed

  # @return [Nsq::Message]
  # @see https://www.rubydoc.info/gems/nsq-ruby/Nsq/Message
  attr_reader :nsq_message

  # @return [String]Nsq::Message body
  attr_reader :raw_body

  alias to_s raw_body

  ##
  # @param nsq_message [Nsq::Message]
  def initialize(nsq_message)
    @nsq_message = nsq_message
    @raw_body = nsq_message.body
  end

  def data
    @data ||= body['data']
  end

  def meta
    @meta ||= body['meta']
  end

  def body
    @body ||= JSON.parse(raw_body)
  end

  ##
  # Finish an NSQ message
  def finish
    return managed if managed

    @managed = :finished
    nsq_message.finish
  end

  ##
  # Requeue an NSQ Message
  # @param timeout [Integer] timeout in milliseconds
  def requeue(timeout = nil)
    return managed if managed
    timeout ||= requeue_period

    @managed = :requeued
    nsq_message.requeue(timeout)
  end

  private

  def requeue_period
    retry_count = [attempts, 30].min
    ((retry_count**4) + 45 + (rand(60) * (retry_count + 1))) * 1_000
  end
end
