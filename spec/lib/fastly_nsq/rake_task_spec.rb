require 'spec_helper'
require 'fastly_nsq/rake_task'

RSpec.describe MessageQueue::RakeTask do
  before(:each) do
    Rake::Task['begin_listening'].clear if Rake::Task.task_defined?('begin_listening')
  end

  describe 'when defining tasks' do
    it 'creates a begin_listening task' do
      MessageQueue::RakeTask.new

      allow_any_instance_of(MessageQueue::RakeTask).to receive(:output) { nil }

      is_defined = Rake::Task.task_defined?(:begin_listening)
      expect(is_defined).to be_truthy
    end

    it 'creates a named task' do
      MessageQueue::RakeTask.new(:test_name)

      allow_any_instance_of(MessageQueue::RakeTask).to receive(:output) { nil }

      is_defined = Rake::Task.task_defined?(:test_name)
      expect(is_defined).to be_truthy
    end
  end

  describe 'when running tasks' do
    it 'runs with inline options defined' do
      options = { topic: 'dwarf', channel: 'star' }
      task = MessageQueue::RakeTask.new(:begin_listening, [:topic, :channel])

      message_queue_listener = double('go', go: nil)
      expect(MessageQueue::Listener).to receive(:new).
        with(options).
        and_return(message_queue_listener)

      allow_any_instance_of(MessageQueue::RakeTask).to receive(:output) { nil }
      Rake::Task['begin_listening'].execute(topic: 'dwarf', channel: 'star')
    end

    it 'runs with specified options if a block is given' do
      MessageQueue::RakeTask.new do |task|
        task.topic   = 'dwarf'
        task.channel = 'star'
      end

      message_queue_listener = double('go', go: nil)
      expect(MessageQueue::Listener).to receive(:new).
        with(topic: 'dwarf', channel: 'star').
        and_return(message_queue_listener)

      allow_any_instance_of(MessageQueue::RakeTask).to receive(:output) { nil }
      Rake::Task['begin_listening'].execute(topic: 'dwarf', channel: 'star')
    end

    it 'uses inline definitions over block assignments' do
      MessageQueue::RakeTask.new(:begin_listening, [:topic, :channel]) do |task|
        task.topic   = 'loud'
        task.channel = 'noise'
      end

      message_queue_listener = double('go', go: nil)
      expect(MessageQueue::Listener).to receive(:new).
        with(topic: 'dwarf', channel: 'star').
        and_return(message_queue_listener)

      allow_any_instance_of(MessageQueue::RakeTask).to receive(:output) { nil }
      Rake::Task['begin_listening'].execute(topic: 'dwarf', channel: 'star')
    end
  end
end
