# frozen_string_literal: true
class FastlyNsq::Launcher
  attr_accessor :manager

  def initialize(options)
    @manager = FastlyNsq::Manager.new options
    @done = false
    @options = options
  end

  def run
    @thread = safe_thread('heartbeat', &method(:start_heartbeat))
    @manager.start
  end

  def quiet
    @done = true
    @manager.quiet
  end

  # Shuts down the process.  This method does not
  # return until all work is complete and cleaned up.
  # It can take up to the timeout to complete.
  def stop
    deadline = Time.now + @options.fetch(:timeout, 10)

    @done = true
    @manager.quiet
    @manager.stop(deadline)
  end

  def stopping?
    @done
  end

  private

  def heartbeat
    FastlyNsq.logger.debug do
      [
        'HEARTBEAT:',
        'thread_status:', @manager.listeners.map(&:status).join(','),
        'listener_count:', @manager.listeners.count
      ].join(' ')
    end
  rescue => e
    FastlyNsq.logger.error("heartbeat error: #{e.message}")
  end

  def start_heartbeat
    loop do
      heartbeat
      sleep 5
    end
    FastlyNsq.logger.info('Heartbeat stopping...')
  end

  def safe_thread(name, &block)
    Thread.new do
      Thread.current['fastly_nsq_label'] = name
      watchdog(name, &block)
    end
  end

  def watchdog(last_words)
    yield
  rescue Exception => ex
    FastlyNsq.logger.error ex
    FastlyNsq.logger.error last_words
    FastlyNsq.logger.error ex.backtrace.join("\n") unless ex.backtrace.nil?
    raise ex
  end
end
