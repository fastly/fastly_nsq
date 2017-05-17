require 'set'

class FastlyNsq::Manager
  attr_reader :listeners, :options

  def initialize(options = {})
    @options = options
    @done = false
    @listeners = Set.new
    @plock = Mutex.new
  end

  def start
    setup_listeners
    @listeners.each(&:start)
  end

  def quiet
    return if @done
    @done = true

    FastlyNsq.logger.info { 'Terminating quiet listeners' }
    @listeners.each(&:terminate)
  end

  PAUSE_TIME = 0.5

  def stop(deadline)
    quiet

    sleep PAUSE_TIME
    return if @listeners.empty?

    FastlyNsq.logger.info { 'Pausing to allow workers to finish...' }
    remaining = deadline - Time.now
    while remaining > PAUSE_TIME
      return if @listeners.empty?
      sleep PAUSE_TIME
      remaining = deadline - Time.now
    end
    return if @listeners.empty?

    hard_shutdown
  end

  def listener_stopped(listener)
    @plock.synchronize do
      @listeners.delete listener
    end
  end

  def listener_killed(listener)
    @plock.synchronize do
      @listeners.delete listener
      unless @done
        new_listener = listener.dup
        @listeners << new_listener
        new_listener.start
      end
    end
  end

  def stopped?
    @done
  end

  private

  def setup_listeners
    FastlyNsq.logger.debug "options #{options.inspect}"
    FastlyNsq.logger.debug "starting listeners: #{FastlyNsq.listeners.inspect}"

    FastlyNsq.listeners.each do |listener|
      @listeners << setup_listener(listener)
    end
  end

  def setup_listener(listener)
    FastlyNsq.logger.info "Listening to topic:'#{listener[:topic]}' on channel: '#{FastlyNsq.channel}'"
    FastlyNsq::Listener.setup(
      {
        topic:        listener[:topic],
        channel:      FastlyNsq.channel,
        processor:    listener[:klass],
        preprocessor: FastlyNsq.preprocessor,
        manager:      self,
      },
    )
  end

  def hard_shutdown
    cleanup = nil
    @plock.synchronize do
      cleanup = @listeners.dup
    end

    unless cleanup.empty?
      FastlyNsq.logger.warn { "Terminating #{cleanup.size} busy worker threads" }
    end

    cleanup.each(&:kill)
  end
end
