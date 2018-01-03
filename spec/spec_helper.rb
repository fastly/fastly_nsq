# frozen_string_literal: true

require 'dotenv'
Dotenv.load

require 'bundler/setup'

Bundler.require(:development)

require 'fastly_nsq'
require 'fastly_nsq/http'
require 'fastly_nsq/testing'

Dir[File.expand_path('../{support,shared,matchers}/**/*.rb', __FILE__)].each { |f| require(f) }

FastlyNsq::Testing.disable!

if ENV['DEBUG']
  Concurrent.use_stdlib_logger(Logger::DEBUG)
  FastlyNsq.logger = Logger.new(STDOUT)
end

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
  config.default_formatter = 'doc' if config.files_to_run.one?

  config.around(:each, fake: true) do |example|
    RSpec::Mocks.with_temporary_scope do
      FastlyNsq::Messages.messages.clear
      FastlyNsq::Testing.fake! { example.run }
    end
  end

  config.around(:each, inline: true) do |example|
    RSpec::Mocks.with_temporary_scope do
      FastlyNsq::Testing.inline! { example.run }
    end
  end

  config.before(:each) do
    FastlyNsq.manager.terminate(0)
    FastlyNsq.manager = FastlyNsq::Manager.new
    FastlyNsq::Testing.reset!
  end
end
