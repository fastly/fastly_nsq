require 'json'

class FastlyNsq::Message
  extend Forwardable

  def_delegators :@nsq_message, :attempts, :finish, :requeue, :touch, :timestamp

  attr_reader :nsq_message, :raw_body
  alias to_s raw_body

  def initialize(nsq_message)
    @nsq_message = nsq_message
    @raw_body = nsq_message.body
  end

  def data
    @data ||= body['data']
  end

  def body
    @body ||= JSON.parse(raw_body)
  end
end
