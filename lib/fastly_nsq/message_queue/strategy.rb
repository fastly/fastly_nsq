class Strategy
  def self.for_queue
    if MessageQueue::FALSY_VALUES.include?(ENV['FAKE_QUEUE'])
      Nsq
    elsif MessageQueue::TRUTHY_VALUES.include?(ENV['FAKE_QUEUE'])
      FakeMessageQueue
    else
      message = "You must set ENV['FAKE_QUEUE'] to either true or false"
      raise InvalidParameterError, message
    end
  end
end
