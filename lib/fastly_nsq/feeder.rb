# frozen_string_literal: true

##
# FastlyNsq::Feeder is a queue interface wrapper for the manager's thread pool.
# This allows a consumer read loop to post a message directly to a
# processor (FastlyNsq::Listener) with a specified priority.
class FastlyNsq::Feeder
  attr_reader :processor, :priority

  ##
  # Create a FastlyNsq::Feeder
  # @param processor [FastlyNsq::Listener]
  # @param priority [Numeric]
  def initialize(processor, priority)
    @processor = processor
    @priority = priority
  end

  ##
  # Send a message to the processor with specified priority
  #
  # This will +post+ to the FastlyNsq.manager.pool with a queue priority and block
  # that will +call+ed. FastlyNsq.manager.pool is a PriorityThreadPool which is a
  # Concurrent::ThreadPoolExecutor that has @queue which in turn is a priority queue
  # that manages job priority
  #
  # The ThreadPoolExecutor is what actually works the @queue and sends +call+ to the queued Proc.
  # When that code is exec'ed +processer.call(message)+ is run. Processor in this context is
  # a FastlyNsq::Listener
  #
  # The block also will log exceptions here because Concurrent::ThreadPoolExecutor will
  # swallow the exception.
  #
  # @param message [Nsq::Message]
  # @see http://ruby-concurrency.github.io/concurrent-ruby/Concurrent/ThreadPoolExecutor.html#post-instance_method
  # @see Nsq::Connection#read_loop
  def push(message)
    FastlyNsq.manager.pool.post(priority) do
      begin
        processor.call(message)
      rescue => ex
        FastlyNsq.logger.error ex
        raise ex
      end
    end
  end
end
