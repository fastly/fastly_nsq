# frozen_string_literal: true

##
# Interface for tracking listeners.
class FastlyNsq::Manager
  DEADLINE = 30
  DEFAULT_POOL_SIZE = 5

  # @return [Boolean] Set true when all listeners are stopped
  attr_reader :done

  # @return [FastlyNsq::PriorityThreadPool]
  attr_reader :pool

  # @return [Logger]
  attr_reader :logger

  ##
  # Create a FastlyNsq::Manager
  #
  # @param logger [Logger]
  # @param pool_options [Hash] Options forwarded to {FastlyNsq::PriorityThreadPool} constructor.
  def initialize(logger: FastlyNsq.logger, **pool_options)
    @done      = false
    @logger    = logger
    @pool      = FastlyNsq::PriorityThreadPool.new(
      { fallback_policy: :caller_runs, max_threads: DEFAULT_POOL_SIZE }.merge(pool_options),
    )
  end

  ##
  # Hash of listeners. Keys are topics, values are {FastlyNsq::Listener} instances.
  # @return [Hash]
  def topic_listeners
    @topic_listeners ||= {}
  end

  ##
  # Array of listening topic names
  # @return [Array]
  def topics
    topic_listeners.keys
  end

  ##
  # Set of {FastlyNsq::Listener} objects
  # @return [Set]
  def listeners
    topic_listeners.values.to_set
  end

  ##
  # Stop the manager.
  # Terminates the listeners and stops all processing in the pool.
  # @param deadline [Integer] Number of seconds to wait for pool to stop processing
  def terminate(deadline = DEADLINE)
    return if done

    stop_listeners

    return if pool.shutdown?

    stop_processing(deadline)

    @done = true
  end

  ##
  # Manager state
  # @return [Boolean]
  def stopped?
    done
  end

  ##
  # Add a {FastlyNsq::Listener} to the @topic_listeners
  # @param listener [FastlyNsq::Listener}
  def add_listener(listener)
    logger.info { "topic #{listener.topic}, channel #{listener.channel}: listening" }

    if topic_listeners[listener.topic]
      logger.warn { "topic #{listener.topic}: duplicate listener" }
    end

    topic_listeners[listener.topic] = listener
  end

  ##
  # Transer listeners to a new manager and stop processing from the existing pool.
  # @param new_manager [FastlyNsq::Manager] new manager to which listeners will be added
  # @param deadline [Integer] Number of seconds to wait for exsiting pool to stop processing
  def transfer(new_manager, deadline: DEADLINE)
    new_manager.topic_listeners.merge!(topic_listeners)
    stop_processing(deadline)
    topic_listeners.clear
    @done = true
  end

  ##
  # Terminate all listeners
  def stop_listeners
    logger.info { 'Stopping listeners' }
    listeners.each(&:terminate)
    topic_listeners.clear
  end

  protected

  ##
  # Shutdown the pool
  # @param deadline [Integer] Number of seconds to wait for pool to stop processing
  def stop_processing(deadline)
    logger.info { 'Stopping processors' }
    pool.shutdown

    logger.info { 'Waiting for processors to finish...' }
    return if pool.wait_for_termination(deadline)

    logger.info { 'Killing processors...' }
    pool.kill
  end
end
