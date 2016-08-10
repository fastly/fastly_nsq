require 'rake'
require 'rake/tasklib'

module FastlyNsq
  class RakeTask < Rake::TaskLib
    attr_accessor :name, :channel, :topics, :preprocessor
    attr_writer :listener, :logger

    def initialize(*args, &task_block)
      @name = args.shift || :begin_listening
      add_rake_task_description_if_one_needed

      task(name, *args) do |_, task_args|
        RakeFileUtils.send(:verbose, verbose) do
          if block_given?
            yield(*[self, task_args].slice(0, task_block.arity))
          end

          initialize_values task_args
          listen_to_configured_topics
        end
      end
    end

    private

    def listen_to_configured_topics
      topic_per_thread do |topic, processor|
        logger.info "Listening to queue, topic:'#{topic}' and channel: '#{channel}'"
        listener.listen_to topic:        topic,
                           channel:      channel,
                           logger:       logger,
                           processor:    processor,
                           preprocessor: preprocessor
        logger.info "... done listening on topic:'#{topic}' and channel: '#{channel}'."
      end
    end

    def require_arg(arg, arg_list)
      arg_list.fetch(arg) { raise ArgumentError, "required configuration '#{arg}' is missing." }
    end

    def add_rake_task_description_if_one_needed
      unless ::Rake.application.last_description
        desc 'Listen to NSQ on topic using channel'
      end
    end

    def topic_per_thread
      listener_threads = []
      topics.each do |(topic, processor)|
        thread = Thread.new do
          yield topic, processor
        end
        thread.abort_on_exception = true
        listener_threads << thread
      end

      listener_threads.map(&:join)
    end

    def listener
      @listener || FastlyNsq::Listener
    end

    def logger
      @logger || FastlyNsq.logger || Logger.new(STDOUT)
    end

    def initialize_values(task_args)
      @channel      ||= require_arg :channel, task_args
      @topics       ||= require_arg :topics, task_args
      @listener     ||= task_args[:listener]
      @logger       ||= task_args[:logger]
      @preprocessor ||= task_args[:preprocessor]
    end
  end
end
