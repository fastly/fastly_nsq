# frozen_string_literal: true
require 'fastly_nsq/safe_thread'

class FastlyNsq::Launcher
  include FastlyNsq::SafeThread

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
end
