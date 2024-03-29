# frozen_string_literal: true

require "spec_helper"

RSpec.describe FastlyNsq::Listener do
  let!(:topic) { "fnsq" }
  let!(:channel) { "fnsq" }
  let!(:messages) { [] }
  let(:processor) { ->(m) { messages << m.body } }

  before { reset_topic(topic, channel: channel) }
  before { expect { subject }.to eventually(be_connected).within(5) }
  after { subject.terminate if subject.connected? }

  subject { described_class.new(topic: topic, channel: channel, processor: processor) }

  describe "#initialize" do
    describe "with FastlyNsq.max_attempts set" do
      let!(:default_max_attempts) { FastlyNsq.max_attempts }
      before { FastlyNsq.max_attempts = 19 }
      after { FastlyNsq.max_attempts = default_max_attempts }

      it "defaults to FastlyNsq.max_attempts" do
        listener = described_class.new(topic: topic, processor: processor, channel: channel)
        expect(listener.max_attempts).to eq(FastlyNsq.max_attempts)

        expect { listener }.to eventually(be_connected).within(5)

        nsq_connection = listener.consumer.connection.connections.values.first # whoa
        expect(nsq_connection.instance_variable_get(:@max_attempts)).to eq(FastlyNsq.max_attempts)
      end
    end

    describe "with FastlyNsq.channel set" do
      let!(:default_channel) { FastlyNsq.channel }
      before { FastlyNsq.channel = "fnsq" }
      after { FastlyNsq.channel = default_channel }

      it "defaults to FastlyNsq.channel" do
        listener = described_class.new(topic: topic, processor: processor)
        expect(listener.channel).to eq(FastlyNsq.channel)
      end
    end

    describe "with FastlyNsq.preprocessor set" do
      let!(:default_preprocessor) { FastlyNsq.preprocessor }
      before { FastlyNsq.preprocessor = "fnsq" }
      after { FastlyNsq.preprocessor = default_preprocessor }

      it "defaults to FastlyNsq.preprocessor" do
        listener = described_class.new(topic: topic, processor: processor, channel: channel)
        expect(listener.preprocessor).to eq(FastlyNsq.preprocessor)
      end
    end

    describe "with FastlyNsq.logger set" do
      let!(:default_logger) { FastlyNsq.logger }
      before { FastlyNsq.logger = Logger.new(nil) }
      after { FastlyNsq.logger = default_logger }

      it "defaults to FastlyNsq.logger" do
        listener = described_class.new(topic: topic, processor: processor, channel: channel)
        expect(listener.logger).to eq(FastlyNsq.logger)
      end
    end

    it "warns when creating a listener for the same topic" do
      expect(FastlyNsq.manager.logger).to receive(:warn).and_yield.and_return(match("#{topic} was added more than once"))

      described_class.new(topic: topic, channel: channel, processor: processor)
    end
  end

  describe "#priority" do
    specify { expect(subject.priority).to eq(described_class::DEFAULT_PRIORITY) }
  end

  describe "#consumer" do
    specify { expect(subject.consumer).to be_a(FastlyNsq::Consumer) }
  end

  describe "connect_timeout" do
    specify { expect(subject.consumer.connect_timeout).to eq(described_class::DEFAULT_CONNECTION_TIMEOUT) }
  end

  it "requires processor to respond_to #call" do
    expect { described_class.new(topic: topic, channel: channel, processor: "foo") }
      .to raise_error(ArgumentError, match("#call"))
  end

  it "requires priority to be a Fixnum" do
    expect { described_class.new(topic: topic, channel: channel, processor: ->(*) {}, priority: "foo") }
      .to raise_error(ArgumentError, match("Integer"))
  end

  describe "#call" do
    it "processes a message" do
      body = {"foo" => "bar"}
      message = spy("message", body: JSON.dump(body), attempts: 1, id: 1)
      expect { subject.call(message) }.to change { messages }.to([body])
    end

    describe "when the processor returns true" do
      let(:processor) { ->(_) { true } }

      it "finishes the message" do
        message = spy("message", body: "{}", attempts: 1, id: 1)
        subject.call(message)

        expect(message).to have_received(:finish)
      end
    end

    describe "when the processor returns false" do
      let(:processor) { ->(_) { false } }

      it "finishes the message" do
        message = spy("message", body: "{}", attempts: 1, id: 1)
        subject.call(message)

        expect(message).not_to have_received(:finish)
      end
    end
  end

  it { should be_connected }

  it "should terminate" do
    expect { subject.terminate }.to change(subject, :connected?).to(false)
  end

  describe "faking", :fake do
    let!(:message) { JSON.dump("foo" => "bar") }

    before { subject }

    it { should be_connected }

    it "should terminate" do
      expect { subject.terminate }.to change(subject, :connected?).to(false)
    end

    it "stores messages produced to the listener's topic" do
      expect do
        FastlyNsq::Producer.new(topic: topic).write(message)
      end.to change { subject.messages.size }.by(1)

      test_message = subject.messages.pop
      expect(test_message.raw_body).to eq(message)
    end

    describe "when the processor returns true" do
      let(:processor) { ->(_) { true } }

      it "drains queued messages" do
        FastlyNsq::Producer.new(topic: topic).write(message)
        expect { subject.drain }.to change { subject.messages.size }.by(-1)
      end
    end

    describe "when the processor returns false" do
      let(:processor) { ->(_) { false } }

      it "does not remove messages" do
        FastlyNsq::Producer.new(topic: topic).write(message)
        expect { subject.drain }.not_to change { subject.messages.size }
      end
    end
  end

  describe "inline", :inline do
    let!(:message) { JSON.dump("foo" => "bar") }
    let!(:processor) { ->(m) { messages << m.raw_body } }

    before { subject }

    it { should be_connected }

    it "should terminate" do
      expect { subject.terminate }.to change(subject, :connected?).to(false)
    end

    describe "when the processor returns true" do
      it "processes and removes messages" do
        expect { FastlyNsq::Producer.new(topic: topic).write(message) }.to change { messages.size }.by(1)
        expect(messages).to contain_exactly(message)
        expect(subject.messages).to be_empty
      end
    end

    describe "when the processor returns false" do
      let(:processor) { ->(_) { false } }

      it "does not remove messages" do
        FastlyNsq::Producer.new(topic: topic).write(message)
        expect { subject.drain }.not_to change { subject.messages.size }
      end
    end
  end
end
