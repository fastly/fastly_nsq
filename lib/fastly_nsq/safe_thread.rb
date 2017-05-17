# frozen_string_literal: true
module FastlyNsq::SafeThread
  def safe_thread(name, &block)
    Thread.new do
      Thread.current['fastly_nsq_label'] = name
      watchdog(name, &block)
    end
  end

  def watchdog(last_words)
    yield
  rescue => ex
    FastlyNsq.logger.error ex
    FastlyNsq.logger.error last_words
    FastlyNsq.logger.error ex.backtrace.join("\n") unless ex.backtrace.nil?
    raise ex
  end
end
