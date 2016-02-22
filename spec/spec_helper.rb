require 'fastly_nsq'
require 'awesome_print'
require 'pry-byebug'

require_relative '../lib/fastly_nsq/sample_message_processor'

MessageProcessor = SampleMessageProcessor

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.default_formatter = 'progress'
  config.disable_monkey_patching!
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.profile_examples = 1
  config.order = :random
  Kernel.srand config.seed

  if config.files_to_run.one?
    config.default_formatter = 'doc'
    config.profile_examples = false
  end

  config.before(:each) do
    load_sample_environment_variables
  #   FakeMessageQueue.reset!
  end

  def load_sample_environment_variables
    env_file = File.open('env_configuration_for_local_gem_tests.yml')

    YAML.load(env_file).each do |key, value|
      ENV[key.to_s] = value
    end
  end
end
