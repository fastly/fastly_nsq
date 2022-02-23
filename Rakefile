# frozen_string_literal: true

require "rubygems"

begin
  require "bundler/setup"
rescue LoadError => e
  abort e.message
end

require "rake"

require "rubygems/tasks"
Gem::Tasks.new

require "rdoc/task"
RDoc::Task.new
task doc: :rdoc

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)

require "bundler/audit/cli"
namespace :bundler do
  desc "Updates the ruby-advisory-db and runs audit"
  task :audit do
    %w[update check].each do |command|
      Bundler::Audit::CLI.start [command]
    end
  end
end

require "standard/rake"

task(:default).clear
task default: ["spec", "standard", "bundler:audit"]
