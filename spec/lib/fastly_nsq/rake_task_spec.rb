require 'spec_helper'
require 'fastly_nsq/rake_task'

RSpec.describe MessageQueue::RakeTask do
  before(:each) do
    Rake::Task.clear
    allow_any_instance_of(MessageQueue::RakeTask).to receive(:output) { nil }
  end

  describe 'when defining tasks' do
    context 'when no task name is provided' do
      it 'creates a task with the default name' do
        default_task_name = 'begin_listening'

        MessageQueue::RakeTask.new
        defined_tasks = Rake::Task.tasks
        first_task_name = defined_tasks.first.name

        expect(first_task_name).to eq default_task_name
      end
    end

    context 'when a task name is passed in' do
      it 'creates a task with the provided name' do
        task_name = 'test_name'

        MessageQueue::RakeTask.new(task_name.to_sym)
        defined_tasks = Rake::Task.tasks
        first_task_name = defined_tasks.first.name

        expect(first_task_name).to eq task_name
      end
    end
  end

  describe 'when running tasks' do
    context 'when multiple topics are defined' do
      it 'creates a listener for each' do
        channel = 'clown_generating_service'
        topics = ['customer_created', 'customer_now_awesome']
        allow(SampleMessageProcessor).to receive(:topics).and_return(topics)
        message_queue_listener = double('listener', go: nil)
        allow(MessageQueue::Listener).to receive(:new).
          and_return(message_queue_listener)

        MessageQueue::RakeTask.new(:begin_listening, [:channel])
        Rake::Task['begin_listening'].execute(channel: channel)

        topics.each do |topic|
          expect(MessageQueue::Listener).to have_received(:new).
            with(topic: topic, channel: channel)
        end
      end
    end

    it 'listens to the command-line-provided channel' do
      channel = 'salesforce'
      topics = ['customer_created']
      allow(SampleMessageProcessor).to receive(:topics).and_return(topics)

      message_queue_listener = double('listener', go: nil)
      expect(MessageQueue::Listener).to receive(:new).
        with(topic: topics.first, channel: channel).
        and_return(message_queue_listener)

      MessageQueue::RakeTask.new(:begin_listening, [:channel])
      Rake::Task['begin_listening'].execute(channel: channel)
    end

    it 'runs with specified channel if a block is given' do
      channel = 'send_new_customers_a_sticker_service'
      topics = ['customer_created']
      allow(SampleMessageProcessor).to receive(:topics).and_return(topics)

      message_queue_listener = double('listener', go: nil)
      expect(MessageQueue::Listener).to receive(:new).
        with(topic: topics.first, channel: channel).
        and_return(message_queue_listener)

      MessageQueue::RakeTask.new do |task|
        task.channel = channel
      end
      Rake::Task['begin_listening'].execute(channel: channel)
    end

    it 'prefers inline channel definition over block assignments' do
      default_channel = 'throw_a_huge_pizza_party_service'
      new_channel = 'send_balloons_to_customer_service'
      topics = ['customer_created']
      allow(SampleMessageProcessor).to receive(:topics).and_return(topics)

      message_queue_listener = double('listener', go: nil)
      expect(MessageQueue::Listener).to receive(:new).
        with(topic: topics.first, channel: new_channel).
        and_return(message_queue_listener)

      MessageQueue::RakeTask.new(:begin_listening, [:channel]) do |task|
        task.channel = default_channel
      end
      Rake::Task['begin_listening'].execute(channel: new_channel)
    end

    context 'when no channel is provided' do
      it 'raises an error' do
        topics = ['customer_created']
        allow(SampleMessageProcessor).to receive(:topics).and_return(topics)

        expect {
          MessageQueue::RakeTask.new(:begin_listening, [:channel])
          Rake::Task['begin_listening'].execute
        }.to raise_error(ArgumentError, /channel is required/)
      end
    end

    context 'when MessageProcessor.topics is not defined' do
      it 'raises an error' do
        channel = 'best_server_number_1'
        allow(SampleMessageProcessor).to receive(:topics).
          and_raise(NoMethodError, "undefined method `topics'")

        expect {
          MessageQueue::RakeTask.new(:begin_listening, [:channel])
          Rake::Task['begin_listening'].execute(channel: channel)
        }.to raise_error(ArgumentError, /MessageProcessor.topics is not defined/)
      end
    end
  end
end
