# frozen_string_literal: true
require 'set'

class FastlyNsq::Manager
  attr_reader :listeners

  def initialize(options = {})
    @options = options
    @done = false
    @listeners = Set.new
    @plock = Mutex.new
  end

  def start
    setup_configured_listeners
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

  def stopped?
    @done
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
        FastlyNsq.logger.info { "recreating listener for: #{listener.identity}" }
        new_listener = listener.reset_then_dup
        @listeners << new_listener
        new_listener.start
      end
    end
  end

  private

  def setup_configured_listeners
    FastlyNsq.logger.debug { "options #{@options.inspect}" }
    FastlyNsq.logger.debug { "starting listeners: #{FastlyNsq.topic_map.inspect}" }

    FastlyNsq.topic_map.each_pair do |topic, processor|
      @listeners << setup_listener(topic, processor)
    end
  end

  def setup_listener(topic, processor)
    FastlyNsq.logger.info { "Listening to topic:'#{topic}' on channel: '#{FastlyNsq.channel}'" }
    FastlyNsq::Listener.new(
      {
        topic:        topic,
        channel:      FastlyNsq.channel,
        processor:    processor,
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
