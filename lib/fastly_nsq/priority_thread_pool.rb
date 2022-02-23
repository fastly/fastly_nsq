# frozen_string_literal: true

class FastlyNsq::PriorityThreadPool < Concurrent::ThreadPoolExecutor
  alias_method :max_threads, :max_length

  def initialize(*)
    super

    @queue = FastlyNsq::PriorityQueue.new(:max)
  end

  # tries to enqueue task
  # @return [true, false] if enqueued
  #
  # @!visibility private
  def ns_enqueue(*args, &task)
    if !ns_limited_queue? || @queue.size < @max_queue
      @queue.push([task, args[1..-1]], args[0])
      true
    else
      false
    end
  end

  # tries to assign task to a worker, tries to get one from @ready or to create new one
  # @return [true, false] if task is assigned to a worker
  #
  # @!visibility private
  def ns_assign_worker(*args, &task)
    super(args[1..-1], &task)
  end
end
