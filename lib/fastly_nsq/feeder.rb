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
  # @param message [Nsq::Message]
  # @see http://ruby-concurrency.github.io/concurrent-ruby/Concurrent/ThreadPoolExecutor.html#post-instance_method
  # @see {Nsq::Connection#read_loop}
  def push(message)
    FastlyNsq.manager.pool.post(priority) { processor.call(message) }
  end
end
