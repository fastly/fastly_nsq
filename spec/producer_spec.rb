# frozen_string_literal: true

require "spec_helper"
RSpec::Matchers.define_negated_matcher :excluding, :include

RSpec.describe FastlyNsq::Producer do
  let!(:topic) { "fnsq" }
  subject { FastlyNsq::Producer.new(topic: topic) }

  before { reset_topic(topic) }
  before { expect { subject }.to eventually(be_connected).within(5) }
  after { subject.terminate if subject.connected? }

  it { should be_connected }

  it "writes a message" do
    subject.write "foo"
    expect { message_count(topic) }.to eventually(eq(1)).within(5)
  end

  it "writes multiple messages" do
    subject.write %w[foo bar]
    expect { message_count(topic) }.to eventually(eq(2)).within(5)
  end

  it "should terminate" do
    expect { subject.terminate }.to change(subject, :connected?).to(false)
    expect(subject.connection).to eq(nil)
  end

  it "does not write after termination" do
    subject.terminate
    expect { subject.write "foo" }.to raise_error(FastlyNsq::NotConnectedError)
  end

  it "can connect after termination" do
    subject.terminate
    expect { subject.connect }.to change(subject, :connected?).to(true)
  end

  it "raises when connection fails within the specified timeframe" do
    allow_any_instance_of(Nsq::Producer).to receive(:connected?).and_return(false)
    logger = spy("logger")
    expect(logger).to receive(:error).and_return("Producer for #{topic} failed to connect!")

    if RUBY_VERSION > "2.4.0"
      expect { FastlyNsq::Producer.new(topic: topic, logger: logger, connect_timeout: 0.2) }
        .to raise_error(FastlyNsq::ConnectionFailed, match(FastlyNsq.lookupd_http_addresses.inspect))
    else
      expect { FastlyNsq::Producer.new(topic: topic, logger: logger, connect_timeout: 0.2) }
        .to raise_error(FastlyNsq::ConnectionFailed)
    end
  end

  describe "connection priorioty" do
    after do
      FastlyNsq.lookupd_http_addresses = nil
      FastlyNsq.producer_nsqds = nil
    end

    it "connects to producer_nsqds if provided" do
      connection = double "FastlyNsq::Producer", connected?: true
      allow(Nsq::Producer).to receive(:new).and_return(connection)

      expect(FastlyNsq.lookupd_http_addresses).not_to be_empty
      expect(FastlyNsq.producer_nsqds).not_to be_empty

      FastlyNsq::Producer.new(topic: topic)
      expect(Nsq::Producer).to have_received(:new).with a_hash_including(nsqd: FastlyNsq.producer_nsqds).and(excluding(:nsqlookupd))
    end

    it "connects to lookupd_http_addresses if producer_nsqds is empty" do
      FastlyNsq.producer_nsqds = []
      connection = double "FastlyNsq::Producer", connected?: true
      allow(Nsq::Producer).to receive(:new).and_return(connection)

      expect(FastlyNsq.lookupd_http_addresses).not_to be_empty
      expect(FastlyNsq.producer_nsqds).to be_empty

      FastlyNsq::Producer.new(topic: topic)
      expect(Nsq::Producer).to have_received(:new).with a_hash_including(nsqlookupd: FastlyNsq.lookupd_http_addresses).and(excluding(:nsqd))
    end

    it "raises when neither producer_nsqds or lookupd_http_addresses are available" do
      FastlyNsq.producer_nsqds = []
      FastlyNsq.lookupd_http_addresses = []
      allow(Nsq::Producer).to receive(:new)

      expect(FastlyNsq.lookupd_http_addresses).to be_empty
      expect(FastlyNsq.producer_nsqds).to be_empty

      expect { FastlyNsq::Producer.new(topic: topic) }
        .to raise_error(FastlyNsq::ConnectionFailed, "One of FastlyNsq.producer_nsqds or FastlyNsq.lookupd_http_addresses must be present")
      expect(Nsq::Producer).not_to have_received(:new)
    end
  end

  describe "faking", :fake do
    it { should be_connected }

    it "should terminate" do
      expect { subject.terminate }.to change(subject, :connected?).to(false)
      expect(subject.connection).to eq(nil)
    end

    it "writes a message" do
      expect { subject.write "foo" }.to change { subject.messages.size }.by(1)
    end

    it "does not write after termination" do
      subject.terminate
      expect { subject.write "foo" }.to raise_error(FastlyNsq::NotConnectedError)
    end

    it "can connect after termination" do
      subject.terminate
      expect { subject.connect }.to change(subject, :connected?).to(true)
    end
  end

  describe "inline", :inline do
    it { should be_connected }

    it "should terminate" do
      expect { subject.terminate }.to change(subject, :connected?).to(false)
      expect(subject.connection).to eq(nil)
    end

    it "writes a message" do
      expect { subject.write "foo" }.to change { subject.messages.size }.by(1)
    end

    it "does not write after termination" do
      subject.terminate
      expect { subject.write "foo" }.to raise_error(FastlyNsq::NotConnectedError)
    end

    it "can connect after termination" do
      subject.terminate
      expect { subject.connect }.to change(subject, :connected?).to(true)
    end
  end
end
