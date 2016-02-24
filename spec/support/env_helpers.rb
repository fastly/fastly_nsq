module EnvHelpers
  def use_fake_connection
    MessageQueue::TRUTHY_VALUES.each do |yes|
      allow(ENV).to receive(:[]).with('FAKE_QUEUE').and_return(yes)
      yield
    end
  end

  def use_real_connection
    MessageQueue::FALSY_VALUES.each do |no|
      allow(ENV).to receive(:[]).with('FAKE_QUEUE').and_return(no)
      yield
    end
  end
end

RSpec.configure do |config|
  config.include EnvHelpers
end
