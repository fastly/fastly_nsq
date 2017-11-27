require 'fastly_nsq'
require 'awesome_print'
require 'pry-byebug'
require 'webmock/rspec'

require_relative 'support/env_helpers'

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
  config.order = :random
  config.profile_examples = 1
  config.run_all_when_everything_filtered = true
  Kernel.srand config.seed

  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end

  config.before(:each) do
    load_sample_environment_variables
    FastlyNsq::FakeBackend.reset!
    WebMock.reset!
  end

  config.around(:each, fake_queue: true) do |example|
    RSpec::Mocks.with_temporary_scope do
      use_fake_connection do
        example.run
      end
    end
  end

  config.around(:each, fake_queue: false) do |example|
    RSpec::Mocks.with_temporary_scope do
      use_real_connection do
        example.run
      end
    end
  end

  def load_sample_environment_variables
    env_file = File.open('env_configuration_for_local_gem_tests.yml')

    YAML.load(env_file).each do |key, value|
      ENV[key.to_s] = value
    end
  end
end
