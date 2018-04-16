# frozen_string_literal: true

class FastlyNsq::Manager
  DEADLINE = 30
  DEFAULT_POOL_SIZE = 5

  attr_reader :done, :pool, :logger

  def initialize(logger: FastlyNsq.logger, **pool_options)
    @done      = false
    @logger    = logger
    @pool      = FastlyNsq::PriorityThreadPool.new(
      { fallback_policy: :caller_runs, max_threads: DEFAULT_POOL_SIZE }.merge(pool_options),
    )
  end

  def topic_listeners
    @topic_listeners ||= {}
  end

  def topics
    topic_listeners.keys
  end

  def listeners
    topic_listeners.values.to_set
  end

  def terminate(deadline = DEADLINE)
    return if done

    stop_listeners

    return if pool.shutdown?

    stop_processing(deadline)

    @done = true
  end

  def stopped?
    done
  end

  def add_listener(listener)
    logger.info { "topic #{listener.topic}, channel #{listener.channel}: listening" }

    if topic_listeners[listener.topic]
      logger.warn { "topic #{listener.topic}: duplicate listener" }
    end

    topic_listeners[listener.topic] = listener
  end

  def transfer(new_manager, deadline: DEADLINE)
    new_manager.topic_listeners.merge!(topic_listeners)
    stop_processing(deadline)
    topic_listeners.clear
    @done = true
  end

  def stop_listeners
    logger.info { 'Stopping listeners' }
    listeners.each(&:terminate)
    topic_listeners.clear
  end

  protected

  def stop_processing(deadline)
    logger.info { 'Stopping processors' }
    pool.shutdown

    logger.info { 'Waiting for processors to finish...' }
    return if pool.wait_for_termination(deadline)

    logger.info { 'Killing processors...' }
    pool.kill
  end
end
