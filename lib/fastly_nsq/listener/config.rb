# frozen_string_literal: true

module FastlyNsq
  class Listener
    class Config
      attr_reader :topic_map

      def initialize
        @topic_map = {}
      end

      def add_topic(topic_name, processor)
        FastlyNsq.logger.info("topic: #{topic_name} : klass #{processor}")
        validate topic_name, processor
        topic_map[topic_name] = processor
      end

      private

      def validate(topic_name, processor)
        unless  processor.respond_to? :process
          error_msg = "ConfigurationError: processor: #{processor} for #{topic_name} does not respond to :process!"
          FastlyNsq.logger.error error_msg
          raise ::ConfigurationError, error_msg
        end

        if topic_map[topic_name]
          FastlyNsq.logger.warn("topic: #{topic_name} was added more than once")
        end
      end
    end
  end
end

class ConfigurationError < StandardError; end
