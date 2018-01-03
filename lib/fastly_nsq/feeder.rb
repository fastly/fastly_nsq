# frozen_string_literal: true

class FastlyNsq::Feeder
  attr_reader :processor, :priority

  def initialize(processor, priority)
    @processor = processor
    @priority = priority
  end

  # @see http://ruby-concurrency.github.io/concurrent-ruby/Concurrent/ThreadPoolExecutor.html#post-instance_method
  # @see {Nsq::Connection#read_loop}
  def push(message)
    FastlyNsq.manager.pool.post(priority) { processor.call(message) }
  end
end
