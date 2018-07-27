# frozen_string_literal: true

begin
  require 'newrelic_rpm'
rescue LoadError # rubocop:disable Lint/HandleExceptions
end

##
# FastlyNsq::NewRelic supports tracing methods with NewRelic
# if the +newrelic_rpm+ is enabled
class FastlyNsq::NewRelic
  include NewRelic::Agent::Instrumentation::ControllerInstrumentation if defined?(::NewRelic)

  CATEGORY = 'OtherTransaction/FastlyNsqProcessor'

  attr_reader :agent

  ##
  # Create a FastlyNsq::NewRelic instance
  # @param agent [#notice_error] optional and should only be used if you need to override the default +NewRelic::Agent+
  # @example
  #   tracer = FastlyNsq::NewRelic.new
  #   tracer.notice_error(exception)
  def initialize(agent = nil)
    @agent = agent || (Object.const_defined?('NewRelic') ? NewRelic::Agent : nil)
  end

  ##
  # Returns true if NewRelic is loaded and available.
  # @return [Boolean]
  def enabled?
    @enabled ||= Object.const_defined?('NewRelic')
  end

  ##
  # Notify NewRelic of an exception only if `enabled? == true`
  # and an +agent+ is defined
  # @param exception [Exception]
  def notice_error(exception)
    return unless enabled? && agent

    agent.notice_error(exception)
  end

  ##
  # Trace passed block with new relic if `enabled? == true`
  # @param trace_args [Hash] tracing parameters passed to NewRelic
  #
  # @see {https://www.rubydoc.info/github/newrelic/rpm/NewRelic%2FAgent%2FInstrumentation%2FControllerInstrumentation:perform_action_with_newrelic_trace}
  def trace_with_newrelic(**args)
    if enabled?
      perform_action_with_newrelic_trace(trace_args(args)) do
        yield
      end
    else
      yield
    end
  end

  private

  def trace_args(**args)
    {
      name: 'call',
      category: CATEGORY,
    }.merge(args)
  end
end
