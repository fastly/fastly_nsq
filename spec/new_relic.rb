# frozen_string_literal: true

require "spec_helper"

RSpec.describe FastlyNsq::NewRelic do
  let(:agent) { double "NewRelic::Agent", notice_error: true }
  let(:tracer) { FastlyNsq::NewRelic.new(agent) }

  describe "#enabled?" do
    it "returns false unless NewRelic is loaded" do
      allow(Object).to receive(:const_defined?).with("NewRelic").and_return(false)
      expect(tracer.enabled?).to be false
    end

    it "returns true id NewRelic is loaded" do
      expect(tracer.enabled?).to be true
    end
  end

  context "enabled" do
    before do
      allow(Object).to receive(:const_defined?).with("NewRelic").and_return(true)
    end

    describe "#notice_error" do
      it "call agent.notice_error" do
        ex = Exception.new

        tracer.notice_error(ex)
        expect(agent).to have_received(:notice_error).with(ex)
      end
    end

    describe "#trace_with_newrelic" do
      it "calls perform_action_with_newrelic_trace and yields" do
        allow(tracer).to receive(:perform_action_with_newrelic_trace).and_yield

        expect { |b| tracer.trace_with_newrelic({}, &b) }.to yield_control
        expect(tracer).to have_received(:perform_action_with_newrelic_trace)
      end

      it "calls perform_action_with_newrelic_trace with trace_args" do
        params = {id: 1, vp: "joe biden"}

        expected = {
          name: "call",
          category: FastlyNsq::NewRelic::CATEGORY,
          params: params,
          class_name: "SomeClass"
        }

        allow(tracer).to receive(:perform_action_with_newrelic_trace).and_yield
        expect { |b| tracer.trace_with_newrelic(params: params, class_name: "SomeClass", &b) }.to yield_control

        expect(tracer).to have_received(:perform_action_with_newrelic_trace).with(expected)
      end

      it "always sends the default trace args" do
        expected = {
          name: "call",
          category: FastlyNsq::NewRelic::CATEGORY
        }
        allow(tracer).to receive(:perform_action_with_newrelic_trace).and_yield

        expect { |b| tracer.trace_with_newrelic(&b) }.to yield_control

        expect(tracer).to have_received(:perform_action_with_newrelic_trace).with(expected)
      end
    end
  end

  context "disabled" do
    before do
      allow(Object).to receive(:const_defined?).with("NewRelic").and_return(false)
    end

    describe "#notice_error" do
      it "returns nil" do
        expect(tracer.notice_error("ex")).to be nil
      end
    end

    describe "#trace_with_newrelic" do
      it "yields" do
        allow(tracer).to receive(:perform_action_with_newrelic_trace)

        expect { |b| tracer.trace_with_newrelic({}, &b) }.to yield_control
        expect(tracer).not_to have_received(:perform_action_with_newrelic_trace)
      end
    end
  end
end
