# frozen_string_literal: true

require 'webmock/rspec/matchers'

RSpec.configure do |config|
  config.include WebMock::API, :webmock
  config.include WebMock::Matchers, :webmock

  config.before(:each, :webmock) do
    WebMock.enable!
  end

  config.after(:each, :webmock) do
    WebMock.disable!
  end

  config.after(:each) do
    WebMock.reset!
  end
end

WebMock::AssertionFailure.error_class = RSpec::Expectations::ExpectationNotMetError
