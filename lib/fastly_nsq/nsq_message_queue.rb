require 'nsq'

class NsqMessageQueue
  def self.producer(topic:)
    Nsq::Producer.new(
      nsqd: ENV.fetch('NSQD_TCP_ADDRESS'),
      topic: topic,
    )
  end

  def self.consumer(topic:, channel:)
    Nsq::Consumer.new(
      nsqlookupd: ENV.fetch('NSQLOOKUPD_HTTP_ADDRESS'),
      topic: topic,
      channel: channel,
    )
  end
end
