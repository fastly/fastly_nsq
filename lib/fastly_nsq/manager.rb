require 'set'

class FastlyNsq::Manager
  attr_reader :listeners, :options

  def initialize(options={})
    @options = options
    @done = false
    @listeners = Set.new

    FastlyNsq.logger.debug { "options #{options.inspect}" }
    FastlyNsq.logger.debug { "starting listeners: #{FastlyNsq.listeners.inspect}" }

    FastlyNsq.listeners.each do |listener|
      topic = listener[:topic]
      FastlyNsq.logger.info "Listening to topic:'#{topic}' on channel: '#{FastlyNsq.channel}'"
      @listeners << FastlyNsq::Listener.setup({
        topic:        topic,
        channel:      FastlyNsq.channel,
        logger:       FastlyNsq.logger,
        processor:    listener[:klass],
        preprocessor: FastlyNsq.preprocessor,
        manager:      self,
      })
    end
    @plock = Mutex.new
  end

  def start
    @listeners.each do |x|
      x.start
    end
  end

  def quiet
    return if @done
    @done = true

    FastlyNsq.logger.info { 'Terminating quiet listeners' }
    @listeners.each do |listener|
      listener.terminate
    end
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
        l = FastlyNsq::Listener.setup *listener.full_args
        @listeners << l
        l.start
      end
    end
  end

  def stopped?
    @done
  end

  private

  def hard_shutdown
    cleanup = nil
    @plock.synchronize do
      cleanup = @listeners.dup
    end

    if cleanup.size > 0
      FastlyNsq.logger.warn { "Terminating #{cleanup.size} busy worker threads" }
    end

    cleanup.each do |listener|
      listener.kill
    end
  end
end
