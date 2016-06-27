require 'rake'
require 'rake/tasklib'

module MessageQueue
  class RakeTask < Rake::TaskLib
    attr_accessor :name, :channel

    def initialize(*args, &task_block)
      @name = args.shift || :begin_listening
      add_rake_task_description_if_one_needed

      task(name, *args) do |_, task_args|
        RakeFileUtils.send(:verbose, verbose) do
          if block_given?
            yield(*[self, task_args].slice(0, task_block.arity))
          end

          if task_args[:channel]
            @channel = task_args[:channel]
          end

          guard_missing_channel
          run_tasks
        end
      end
    end

    private

    def add_rake_task_description_if_one_needed
      unless ::Rake.application.last_description
        desc 'Listen to NSQ on topic using channel'
      end
    end

    def run_tasks
      listener_threads = []

      topics.each do |topic|
        listener_threads << Thread.new do
          wrap_helpful_output(topic) do
            MessageQueue::Listener.new(topic: topic, channel: channel).go
          end
        end
      end

      while listener_threads.any?(&:status)
        listener_threads.each do |thread|
          thread.join(1)
        end
      end
    end

    def guard_missing_channel
      unless channel
        raise ArgumentError, "channel is required. Received channel: #{channel}"
      end
    end

    def wrap_helpful_output(topic)
      output "Listening to queue, topic:'#{topic}' and channel: '#{channel}'"
      yield
      output "... done listening on topic:'#{topic}' and channel: '#{channel}'."
    end

    def topics
      MessageProcessor.topics
    rescue NoMethodError => exception
      if exception.message =~ /undefined method `topics'/
        raise ArgumentError, 'MessageProcessor.topics is not defined.'
      else
        raise exception
      end
    end

    def output(string)
      logger.info(string)
    end

    def logger
      MessageQueue.logger = Logger.new(STDOUT)
    end
  end
end
