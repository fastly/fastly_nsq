# frozen_string_literal: true

require "spec_helper"

RSpec.describe FastlyNsq::Consumer do
  let!(:topic) { "fnsq" }
  let!(:channel) { "fnsq" }
  let!(:queue) { nil }

  subject { described_class.new(topic: topic, channel: channel, queue: queue) }

  before { reset_topic(topic, channel: channel) }
  before { expect { subject }.to eventually(be_connected).within(5) }

  after { subject.terminate if subject.connected? }

  it { should be_connected }

  it "should terminate" do
    expect { subject.terminate }.to change(subject, :connected?).to(false)
  end

  describe "with a specified queue" do
    let!(:queue) { Queue.new }

    it "passes #queue to Nsq::Consumer" do
      message = "foo"

      FastlyNsq::Messenger.deliver(message: message, topic: topic)

      expect { queue.size }.to eventually(eq 1).within(15)
      fastly_message = FastlyNsq::Message.new(queue.pop)

      expect(fastly_message.data).to eq(message)
      fastly_message.finish
    end
  end

  it { should delegate(:size).to(:connection) }
  it { should delegate(:terminate).to(:connection) }
  it { should delegate(:pop).to(:connection) }
  it { should delegate(:pop_without_blocking).to(:connection) }

  describe "with a message" do
    let(:message) { "foo" }

    before { FastlyNsq::Messenger.deliver(message: message, topic: topic) }

    it "should not be empty" do
      expect { subject }.to eventually(be_empty).within(15)
    end

    describe "that has finished" do
      before { subject.pop.finish }

      it { should be_empty }
    end
  end
end
