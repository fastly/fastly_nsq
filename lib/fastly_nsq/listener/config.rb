# frozen_string_literal: true
module FastlyNsq
  class Listener::Config
    attr_reader :listeners

    def initialize
      @listeners = []
    end

    def add(topic_name, klass)
      FastlyNsq.logger.info("topic: #{topic_name} : klass #{klass}")
      listeners << { topic: topic_name, klass: klass }
    end
  end
end
