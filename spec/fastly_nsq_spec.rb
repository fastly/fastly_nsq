# frozen_string_literal: true

require "spec_helper"

RSpec.describe FastlyNsq do
  describe "#configure" do
    specify { expect { |b| described_class.configure(&b) }.to yield_with_args(described_class) }
  end

  describe "#listen" do
    let!(:default_channel) { subject.channel }
    let!(:topic) { "fnsq" }

    before { subject.channel = "fnsq" }
    after { subject.channel = default_channel }

    it "creates a listener" do
      expect { subject.listen topic, ->(*) {} }.to change { subject.manager.topics }.to([topic])
    end

    it "creates a listener with a specific priority" do
      listener = subject.listen topic, ->(*) {}, priority: 10
      expect(listener.priority).to eq(10)
    end
  end

  describe "#channel=" do
    let!(:default_channel) { subject.channel }
    after { subject.channel = default_channel }

    it "allows the channel to be set and retrieved" do
      expect(subject.channel).to be_nil
      subject.channel = "foo"
      expect(subject.channel).to eq("foo")
    end
  end

  describe "#logger" do
    let!(:default_logger) { subject.logger }
    after { subject.logger = default_logger }

    it "returns the set logger" do
      logger = Logger.new(nil)
      subject.logger = logger

      expect(subject.logger).to eq logger
    end

    it "sets the default logger if none is set" do
      subject.instance_variable_set(:@logger, nil)
      expect(subject.instance_variable_get(:@logger)).to be nil
      logger = subject.logger

      expect(logger).to be_instance_of(Logger)
      expect(logger.instance_variable_get(:@logdev).dev).to eq($stderr)
      expect(logger).to eq(Nsq.logger)
    end
  end

  describe "#logger=" do
    let!(:default_logger) { subject.logger }
    after { subject.logger = default_logger }

    it "allows the logger to be set and retrieved" do
      logger = Logger.new($stdout)
      subject.logger = logger

      expect(subject.logger).to eq logger
    end

    it "sets Nsq.logger" do
      logger = Logger.new($stdout)
      subject.logger = logger

      expect(Nsq.logger).to eq logger
    end
  end

  describe "#manager" do
    it "represents the active default manager" do
      expect(subject.manager).not_to be_stopped
    end
  end

  describe "#manager=" do
    it "transfers to specified manager" do
      old_manager = subject.manager
      new_manager = FastlyNsq::Manager.new

      expect(old_manager).to receive(:transfer).with(new_manager)

      subject.manager = new_manager
    end
  end

  describe "#lookupd_http_addresses" do
    after { subject.instance_variable_set(:@lookups, nil) }

    it "retreives NSQLOOKUPD_HTTP_ADDRESS by default" do
      expect(subject.lookupd_http_addresses).to eq(ENV["NSQLOOKUPD_HTTP_ADDRESS"].split(","))
    end

    it "returns the value of the instance variable" do
      subject.instance_variable_set(:@lookups, ["lolcathost"])

      expect(subject.lookupd_http_addresses).to eq(["lolcathost"])
    end
  end

  describe "#lookupd_http_addresses=" do
    let!(:default_loookups) { subject.lookupd_http_addresses }
    after { subject.lookupd_http_addresses = default_loookups }

    it "allows the lookups to be set and retrieved" do
      lookups = ["lolcathost:1234"]
      subject.lookupd_http_addresses = lookups

      expect(subject.lookupd_http_addresses).to eq lookups
    end
  end

  describe "#producer_nsqds" do
    after { subject.instance_variable_set(:@producer_nsqds, nil) }

    it "retreives NSQD_PRODUCERS by default" do
      expect(subject.producer_nsqds).to eq(ENV["NSQD_PRODUCERS"].split(","))
    end

    it "returns the value of the instance variable" do
      subject.instance_variable_set(:@producer_nsqds, ["producer:1234"])

      expect(subject.producer_nsqds).to eq(["producer:1234"])
    end
  end

  describe "#producer_nsqds=" do
    let!(:default_producers) { subject.producer_nsqds }
    after { subject.producer_nsqds = default_producers }

    it "allows the producer_nsqds to be set and retrieved" do
      producers = ["producer:1234"]
      subject.producer_nsqds = producers

      expect(subject.producer_nsqds).to eq producers
    end
  end

  describe "#consumer_nsqds" do
    after { subject.instance_variable_set(:@consumer_nsqds, nil) }

    it "retreives NSQD_CONSUMERS by default" do
      expect(subject.consumer_nsqds).to eq(ENV["NSQD_CONSUMERS"].split(","))
    end

    it "returns the value of the instance variable" do
      subject.instance_variable_set(:@consumer_nsqds, ["consumer:1234"])

      expect(subject.consumer_nsqds).to eq(["consumer:1234"])
    end
  end

  describe "#consumer_nsqds=" do
    let!(:default_consumers) { subject.consumer_nsqds }
    after { subject.consumer_nsqds = default_consumers }

    it "allows the consumer_nsqds to be set and retrieved" do
      consumers = ["consumer:1234"]
      subject.consumer_nsqds = consumers

      expect(subject.consumer_nsqds).to eq consumers
    end
  end

  describe "#on" do
    before { FastlyNsq.events.each { |(_, v)| v.clear } }
    after { FastlyNsq.events.each { |(_, v)| v.clear } }

    it "registers callbacks for events" do
      %i[startup shutdown heartbeat].each do |event|
        block = -> {}
        FastlyNsq.on(event, &block)
        expect(FastlyNsq.events[event]).to eq([block])
      end
    end

    it "limits callback registration to valid events" do
      expect { FastlyNsq.on(:foo, &-> {}) }.to raise_error(ArgumentError, /Invalid event name/)
    end
  end
end
