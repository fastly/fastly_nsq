require 'rake'
require 'rake/tasklib'

module MessageQueue
  class RakeTask < Rake::TaskLib
    attr_accessor :name, :topic, :channel

    def initialize(*args, &task_block)
      @name = args.shift || :begin_listening

      desc 'Listen to NSQ on topic using channel' unless ::Rake.application.last_comment

      task(name, *args) do |_, task_args|
        RakeFileUtils.send(:verbose, verbose) do
          yield(*[self, task_args].slice(0, task_block.arity)) if block_given?
          @topic   = task_args[:topic] if task_args[:topic]
          @channel = task_args[:channel] if task_args[:channel]
          run_task
        end
      end
    end

    private

    def run_task
      raise ArgumentError, "topic and channel are required. Recieved topic: #{topic} channel: #{channel}" unless topic && channel

      output "Listening to the queue on topic:'#{topic}' and channel ':#{channel}'"

      MessageQueue::Listener.new(topic: topic, channel: channel).go

      output "... done listening to queue on topic:'#{topic}' and channel ':#{channel}'"
    end

    # wrapping output for stubbing in tests to avoid clobbering output...
    def output(str)
      puts str
    end
  end
end
