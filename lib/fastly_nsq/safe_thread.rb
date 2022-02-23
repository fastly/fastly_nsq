# frozen_string_literal: true

module FastlyNsq::SafeThread
  def safe_thread(name, &block)
    Thread.new do
      Thread.current["fastly_nsq_label"] = name
      watchdog(name, &block)
    end
  end

  def watchdog(last_words)
    yield
  rescue => e
    FastlyNsq.logger.error e
    FastlyNsq.logger.error last_words
    FastlyNsq.logger.error e.backtrace.join("\n") unless e.backtrace.nil?
    raise e
  end
end
