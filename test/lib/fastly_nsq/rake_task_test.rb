require 'test_helper'
require 'fastly_nsq/rake_task'

describe MessageQueue::RakeTask do
  before(:each) do
    Rake::Task['begin_listening'].clear if Rake::Task.task_defined?('begin_listening')
  end

  describe 'defining tasks' do
    it 'creates a begin_listening task' do
      MessageQueue::RakeTask.new

      allow_any_instance_of(MessageQueue::RakeTask).to receive(:output) { nil }
      assert_equal true, Rake::Task.task_defined?(:begin_listening)
    end

    it 'creates a named task' do
      MessageQueue::RakeTask.new(:test_name)

      allow_any_instance_of(MessageQueue::RakeTask).to receive(:output) { nil }
      assert_equal true, Rake::Task.task_defined?(:test_name)
    end
  end

  describe 'running tasks' do
    it 'runs with inline options defined' do
      MessageQueue::RakeTask.new(:begin_listening, [:topic, :channel])

      dbl = double('go', go: nil)
      expect(MessageQueue::Listener).to receive(:new).
        with(topic: 'dwarf', channel: 'star').
        and_return(dbl)

      allow_any_instance_of(MessageQueue::RakeTask).to receive(:output) { nil }
      Rake::Task['begin_listening'].execute(topic: 'dwarf', channel: 'star')
    end

    it 'runs with specified options if a block is given' do
      MessageQueue::RakeTask.new do |task|
        task.topic   = 'dwarf'
        task.channel = 'star'
      end

      dbl = double('go', go: nil)
      expect(MessageQueue::Listener).to receive(:new).
        with(topic: 'dwarf', channel: 'star').
        and_return(dbl)

      allow_any_instance_of(MessageQueue::RakeTask).to receive(:output) { nil }
      Rake::Task['begin_listening'].execute(topic: 'dwarf', channel: 'star')
    end

    it 'uses inline over block' do
      MessageQueue::RakeTask.new(:begin_listening, [:topic, :channel]) do |task|
        task.topic   = 'loud'
        task.channel = 'noise'
      end

      dbl = double('go', go: nil)
      expect(MessageQueue::Listener).to receive(:new).
        with(topic: 'dwarf', channel: 'star').
        and_return(dbl)

      allow_any_instance_of(MessageQueue::RakeTask).to receive(:output) { nil }
      Rake::Task['begin_listening'].execute(topic: 'dwarf', channel: 'star')
    end
  end
end
