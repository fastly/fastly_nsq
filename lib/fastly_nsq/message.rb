require 'json'

class FastlyNsq::Message
  attr_reader :raw_body
  alias :to_s :raw_body

  def initialize(raw_body)
    @raw_body = raw_body
  end

  def data
    @data ||= body['data']
  end

  def body
    @body ||= JSON.parse(raw_body)
  end
end
