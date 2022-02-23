# frozen_string_literal: true

require "spec_helper"

RSpec.describe FastlyNsq::Manager do
  let!(:topic) { "fnsq" }
  let!(:channel) { "fnsq" }

  subject { FastlyNsq.manager }

  before { reset_topic(topic, channel: channel) }

  after { subject.terminate(1) unless subject.stopped? }

  it { should_not be_stopped }

  describe "#initialize" do
    it "allows max_threads to be specified" do
      max_threads = FastlyNsq.max_processing_pool_threads * 2
      manager = described_class.new(max_threads: max_threads)

      expect(manager.pool.max_threads).to eq(max_threads)
    end

    it "defaults max_threads to FastlyNsq.max_processing_pool_threads" do
      expect(subject.pool.max_threads).to eq(FastlyNsq.max_processing_pool_threads)
    end

    it "allows fallback_policy to be specified" do
      manager = described_class.new(fallback_policy: :abort)

      expect(manager.pool.fallback_policy).to eq(:abort)
    end

    it "defaults fallback_policy to caller_runs" do
      expect(subject.pool.fallback_policy).to eq(:caller_runs)
    end

    it "defaults logger to FastlyNsq.logger" do
      expect(subject.logger).to eq(FastlyNsq.logger)
    end

    it "allows logger to be specified" do
      logger = Logger.new(nil)
      manager = described_class.new(logger: logger)

      expect(manager.logger).to eq(logger)
    end
  end

  context "with a listener" do
    let!(:listener) { FastlyNsq::Listener.new(topic: topic, channel: channel, processor: ->(*) {}) }
    before { expect { listener }.to eventually(be_connected).within(5) }

    it "tracks listener" do
      expect(subject.listeners).to contain_exactly(listener)
    end

    it "tracks topic listeners" do
      expect(subject.topic_listeners).to eq(topic => listener)
    end

    it "tracks topics" do
      expect(subject.topics).to contain_exactly(topic)
    end

    describe "#terminate" do
      it "terminates listeners" do
        expect { subject.terminate(2) }.to change(listener, :connected?).to(false)
      end

      it "terminates the processing pool" do
        expect { subject.terminate(2) }.to change(subject.pool, :shutdown?).to(true)
      end

      it "stops" do
        expect { subject.terminate(2) }.to change(subject, :stopped?).from(false).to(true)
      end

      context "when the pool does not terminate within a the specified timeframe" do
        before { expect(subject.pool).to receive(:shutdown).and_return(false) }

        it "kills the pool" do
          expect(subject.pool).to receive(:kill).once.and_call_original

          expect { subject.terminate(0.1) }.to change(subject.pool, :shutdown?).to(true)
        end
      end
    end
  end

  it "transfers" do
    manager = described_class.new

    listener = nil
    # register listener with default manager
    expect { listener = FastlyNsq::Listener.new(topic: topic, channel: channel, processor: ->(*) {}) }
      .to change { FastlyNsq.manager.listeners.size }.by(1)
    expect { listener }.to eventually(be_connected).within(5)

    # transfer listener to new manager
    expect { FastlyNsq.manager.transfer(manager) }
      .to change { manager.listeners.size }.by(1)
      .and change { FastlyNsq.manager.listeners.size }.by(-1)

    # old manager processing is disabled
    expect(FastlyNsq.manager.pool).to be_shutdown
    # listener is still connected
    expect(listener).to be_connected
  end
end
