# frozen_string_literal: true

require 'json'

class FastlyNsq::Message
  extend Forwardable

  def_delegators :@nsq_message, :attempts, :touch, :timestamp

  attr_reader :managed, :nsq_message, :raw_body
  alias to_s raw_body

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
