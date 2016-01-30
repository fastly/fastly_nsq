require 'rubygems'

begin
  require 'bundler/setup'
rescue LoadError => error
  abort error.message
end

require 'fastly_nsq'

require 'minitest/autorun'
require 'awesome_print'
require 'pry-byebug'
require_relative '../lib/fastly_nsq/sample_message_processor'

MessageProcessor = SampleMessageProcessor

MiniTest::Spec.before do
  load_sample_environment_variables
  FakeMessageQueue.reset!
end

def load_sample_environment_variables
  env_file = File.open('env_configuration_for_local_gem_tests.yml')

  YAML.load(env_file).each do |key, value|
    ENV[key.to_s] = value
  end
end

require 'rspec/mocks'
module MinitestRSpecMocksIntegration
  include ::RSpec::Mocks::ExampleMethods

  def before_setup
    ::RSpec::Mocks.setup
    super
  end

  def after_teardown
    super
    ::RSpec::Mocks.verify
  ensure
    ::RSpec::Mocks.teardown
  end
end

class MiniTest::Spec
  include MinitestRSpecMocksIntegration
end
