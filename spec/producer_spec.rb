# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FastlyNsq::Producer do
  let!(:topic) { 'fnsq' }
  subject { FastlyNsq::Producer.new(topic: topic) }

  before { reset_topic(topic) }
  before { expect { subject }.to eventually(be_connected).within(5) }
  after { subject.terminate if subject.connected? }

  it { should be_connected }

  it 'writes a message' do
    expect { subject.write 'foo' }.to change { message_count(topic) }.by(1)
  end

  it 'should terminate' do
    expect { subject.terminate }.to change(subject, :connected?).to(false)
    expect(subject.connection).to eq(nil)
  end

  it 'does not write after termination' do
    subject.terminate
    expect { subject.write 'foo' }.to raise_error(FastlyNsq::NotConnectedError)
  end

  it 'can connect after termination' do
    subject.terminate
    expect { subject.connect }.to change(subject, :connected?).to(true)
  end

  it 'raises when connection fails within the specified timeframe' do
    allow_any_instance_of(Nsq::Producer).to receive(:connected?).and_return(false)
    logger = spy('logger')
    expect(logger).to receive(:error).and_return("Producer for #{topic} failed to connect!")

    expect { FastlyNsq::Producer.new(topic: topic, logger: logger, connect_timeout: 0.2) }.
      to raise_error(Timeout::Error)
  end

  describe 'faking', :fake do
    it { should be_connected }

    it 'should terminate' do
      expect { subject.terminate }.to change(subject, :connected?).to(false)
      expect(subject.connection).to eq(nil)
    end

    it 'writes a message' do
      expect { subject.write 'foo' }.to change { subject.messages.size }.by(1)
    end

    it 'does not write after termination' do
      subject.terminate
      expect { subject.write 'foo' }.to raise_error(FastlyNsq::NotConnectedError)
    end

    it 'can connect after termination' do
      subject.terminate
      expect { subject.connect }.to change(subject, :connected?).to(true)
    end
  end

  describe 'inline', :inline do
    it { should be_connected }

    it 'should terminate' do
      expect { subject.terminate }.to change(subject, :connected?).to(false)
      expect(subject.connection).to eq(nil)
    end

    it 'writes a message' do
      expect { subject.write 'foo' }.to change { subject.messages.size }.by(1)
    end

    it 'does not write after termination' do
      subject.terminate
      expect { subject.write 'foo' }.to raise_error(FastlyNsq::NotConnectedError)
    end

    it 'can connect after termination' do
      subject.terminate
      expect { subject.connect }.to change(subject, :connected?).to(true)
    end
  end
end
