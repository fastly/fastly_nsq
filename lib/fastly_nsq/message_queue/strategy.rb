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

  FALSY_VALUES  = [false, 0, '0', 'false', 'FALSE', 'off', 'OFF', nil].freeze
  TRUTHY_VALUES = [true, 1, '1', 'true', 'TRUE', 'on', 'ON'].freeze
  end
end
