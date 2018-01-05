# frozen_string_literal: true

require 'fastly_nsq/safe_thread'

class FastlyNsq::Launcher
  include FastlyNsq::SafeThread
  extend Forwardable

  attr_reader :timeout

  def manager
    FastlyNsq.manager
  end

  def initialize(timeout: 5, **options)
    @done    = false
    @timeout = timeout

    FastlyNsq.manager = FastlyNsq::Manager.new(options)
  end

  def run
    @thread = safe_thread('heartbeat', &method(:start_heartbeat))
  end

  def stop
    @done = true
    manager.terminate(timeout)
  end

  def stop_listeners
    @done = true
    manager.stop_listeners
  end

  def stopping?
    @done
  end

  private

  def heartbeat
    FastlyNsq.logger.debug do
      [
        'HEARTBEAT:',
        'thread_status:', @manager.listeners.map(&:status).join(', '),
        'listener_count:', @manager.listeners.count
      ].join(' ')
    end

    # TODO: Check the health of the system overall and kill it if needed
    #       ::Process.kill('dieing because...', $$)
  rescue => e
    FastlyNsq.logger.error "heartbeat error: #{e.message}"
  end

  def start_heartbeat
    loop do
      heartbeat
      sleep 5
    end
    FastlyNsq.logger.info('Heartbeat stopping...')
  end
end
