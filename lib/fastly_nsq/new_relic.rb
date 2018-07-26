# frozen_string_literal: true

class FastlyNsq::NewRelic
  include NewRelic::Agent::Instrumentation::ControllerInstrumentation if defined?(::NewRelic)

  attr_reader :agent

  def initialize(agent = NewRelic::Agent)
    @agent = agent
  end

  def enabled?
    @enabled ||= Object.const_defined?('NewRelic')
  end

  def notice_error(ex)
    return unless enabled?

    agent.notice_error(ex)
  end

  def trace_with_newrelic(trace_args)
    if enabled?
      perform_action_with_newrelic_trace(trace_args) do
        yield
      end
    else
      yield
    end
  end
end
