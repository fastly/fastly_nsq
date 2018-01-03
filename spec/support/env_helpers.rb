# frozen_string_literal: true

module EnvHelpers
  def use_fake_connection
    allow(ENV).to receive(:[]).with('FAKE_QUEUE').and_return(true)
    yield
  end

  def use_real_connection
    allow(ENV).to receive(:[]).with('FAKE_QUEUE').and_return(false)
    yield
  end
end

RSpec.configure do |config|
  config.include EnvHelpers
end
