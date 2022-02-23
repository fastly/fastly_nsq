# frozen_string_literal: true

require "fastly_nsq/safe_thread"

##
# FastlyNsq::Launcher is a lighweight wrapper of a thread manager
# and heartbeat.
#
# This class is used internally by FastlyNsq::CLI.
class FastlyNsq::Launcher
  include FastlyNsq::SafeThread

  attr_reader :timeout, :logger
  attr_accessor :pulse

  def manager
    FastlyNsq.manager
  end

  def initialize(**options)
    @done = false
    @timeout = options[:timeout] || 5
    @pulse = options[:pulse] || 5
    @logger = options[:logger] || FastlyNsq.logger

    FastlyNsq.manager = FastlyNsq::Manager.new(**options)
    FastlyNsq.fire_event :startup
  end

  def beat
    @heartbeat ||= safe_thread("heartbeat", &method(:start_heartbeat))
  end

  def stop
    @done = true
    manager.terminate(timeout)
    FastlyNsq.fire_event :shutdown
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
    logger.debug do
      [
        "HEARTBEAT:",
        "busy:", manager.pool.length,
        "processed:", manager.pool.completed_task_count,
        "max_threads:", manager.pool.max_length,
        "max_queue_size:", manager.pool.largest_length,
        "listeners:", manager.listeners.count
      ].join(" ")
    end

    # TODO: Check the health of the system overall and kill it if needed
    #       ::Process.kill('dieing because...', $$)
  rescue => e
    logger.error "Heartbeat error: #{e.message}"
  ensure
    FastlyNsq.fire_event :heartbeat
  end

  def start_heartbeat
    until manager.stopped?
      heartbeat
      sleep pulse
    end
    logger.info("Heartbeat stopping...")
  end
end
