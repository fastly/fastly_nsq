require 'spec_helper'
require 'fastly_nsq/rake_task'

RSpec.describe FastlyNsq::RakeTask do
  before(:each) do
    Rake::Task.clear
    @original_logger = FastlyNsq.logger
    FastlyNsq.logger = Logger.new(nil)
  end

  after do
    FastlyNsq.logger = @original_logger
  end

  describe 'when defining tasks' do
    context 'when no task name is provided' do
      it 'creates a task with the default name' do
        default_task_name = 'begin_listening'

        FastlyNsq::RakeTask.new
        defined_tasks = Rake::Task.tasks
        first_task_name = defined_tasks.first.name

        expect(first_task_name).to eq default_task_name
      end
    end

    context 'when a task name is passed in' do
      it 'creates a task with the provided name' do
        task_name = 'test_name'

        FastlyNsq::RakeTask.new(task_name.to_sym)
        defined_tasks = Rake::Task.tasks
        first_task_name = defined_tasks.first.name

        expect(first_task_name).to eq task_name
      end
    end
  end

  describe 'when running tasks' do
    context 'when no channel is provided' do
      it 'raises an error' do
        expect do
          FastlyNsq::RakeTask.new(:begin_listening, [:channel])
          Rake::Task['begin_listening'].execute
        end.to raise_error(ArgumentError, /required.+channel/)
      end
    end

    context 'when no topics are provided' do
      it 'raises an error' do
        channel = 'best_server_number_1'

        expect do
          FastlyNsq::RakeTask.new(:begin_listening, [:channel])
          Rake::Task['begin_listening'].execute(channel: channel)
        end.to raise_error(ArgumentError, /required.+topics/)
      end
    end

    context 'when a channel and topics are defined' do
      let(:channel)  { 'clown_generating_service' }
      let(:topics)   { { customer_created: :fake_processor } }
      let(:listener) { class_double FastlyNsq::Listener, listen_to: nil }

      it 'configures via a block if one is given' do
        FastlyNsq::RakeTask.new(:begin_listening, %i[channel topics]) do |task|
          task.channel  = channel
          task.topics   = topics
          task.listener = listener
        end

        Rake::Task['begin_listening'].execute

        expect(listener).to have_received(:listen_to).
          with(hash_including(topic: :customer_created, channel: channel))
      end

      it 'prefers inline channel definition over block assignments' do
        new_channel = 'send_balloons_to_customer_service'

        FastlyNsq::RakeTask.new(:begin_listening, %i[channel topics]) do |task|
          task.channel  = channel
          task.topics   = topics
          task.listener = listener
        end

        Rake::Task['begin_listening'].execute(channel: new_channel, topics: topics, listener: listener)

        expect(listener).to have_received(:listen_to).
          with(hash_including(topic: :customer_created, channel: channel))
      end

      it 'configures a listener for each topic if there are multiple' do
        topics = %w(foo bar baz quuz etc)

        FastlyNsq::RakeTask.new(:begin_listening, %i[channel topics listener])
        Rake::Task['begin_listening'].execute(channel: channel, topics: topics, listener: listener)

        topics.each do |(topic, processor)|
          expect(listener).to have_received(:listen_to).
            with(hash_including(topic: topic, channel: channel, processor: processor))
        end
      end

      context 'and preprocessor is defined' do
        it 'passes preprocessor to the listener' do
          FastlyNsq::RakeTask.new(:begin_listening) do |task|
            task.channel      = channel
            task.topics       = topics
            task.listener     = listener
            task.preprocessor = :noop
          end

          Rake::Task['begin_listening'].execute

          expect(listener).to have_received(:listen_to).
            with(hash_including(preprocessor: :noop))
        end
      end

      context 'and logger is defined' do
        let(:logger) { double 'Logger', info: nil }

        it 'passes logger to the listener' do
          FastlyNsq::RakeTask.new(:begin_listening) do |task|
            task.channel  = channel
            task.topics   = topics
            task.listener = listener
            task.logger   = logger
          end

          Rake::Task['begin_listening'].execute

          expect(listener).to have_received(:listen_to).
            with(hash_including(logger: logger))
        end
      end
    end
  end
end
