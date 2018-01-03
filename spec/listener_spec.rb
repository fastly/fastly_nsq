# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FastlyNsq::Listener do
  let!(:topic) { 'fnsq' }
  let!(:channel) { 'fnsq' }
  let!(:messages) { [] }
  let(:processor) { ->(m) { messages << m.body } }

  before { reset_topic(topic, channel: channel) }
  before { expect { subject }.to eventually(be_connected).within(5) }
  after  { subject.terminate if subject.connected? }

  subject { described_class.new(topic: topic, channel: channel, processor: processor) }

  it 'requires processor to respond_to #call' do
    expect { described_class.new(topic: topic, channel: channel, processor: 'foo') }.
      to raise_error(ArgumentError, match('#call'))
  end

  it 'requires priority to be a Fixnum' do
    expect { described_class.new(topic: topic, channel: channel, processor: ->(*) {}, priority: 'foo') }.
      to raise_error(ArgumentError, match('Integer'))
  end

  it 'processes a message' do
    body = { 'foo' => 'bar' }
    message = spy('message', body: JSON.dump(body))
    expect { subject.call(message) }.to change { messages }.to([body])
  end

  it { should be_connected }

  it 'should terminate' do
    expect { subject.terminate }.to change(subject, :connected?).to(false)
  end

  describe 'when the processor returns true' do
    let(:processor) { ->(_) { true } }

    it 'finishes the message' do
      message = spy('message', body: '{}')
      subject.call(message)

      expect(message).to have_received(:finish)
    end
  end

  describe 'when the processor returns false' do
    let(:processor) { ->(_) { false } }

    it 'finishes the message' do
      message = spy('message', body: '{}')
      subject.call(message)

      expect(message).not_to have_received(:finish)
    end
  end

  describe 'faking', :fake do
    let!(:message) { { 'foo' => 'bar' } }

    before { subject }

    it { should be_connected }

    it 'should terminate' do
      expect { subject.terminate }.to change(subject, :connected?).to(false)
    end

    it "stores messages produced to the listener's topic" do
      expect do
        FastlyNsq::Producer.new(topic: topic).write(message)
      end.to change { subject.messages.size }.by(1)

      test_message = subject.messages.pop
      expect(test_message.raw_body).to eq(message)
    end

    describe 'when the processor returns true' do
      let(:processor) { ->(_) { true } }

      it 'drains queued messages' do
        FastlyNsq::Producer.new(topic: topic).write(message)
        expect { subject.drain }.to change { subject.messages.size }.by(-1)
      end
    end

    describe 'when the processor returns false' do
      let(:processor) { ->(_) { false } }

      it 'does not remove messages' do
        FastlyNsq::Producer.new(topic: topic).write(message)
        expect { subject.drain }.not_to change { subject.messages.size }
      end
    end
  end

  describe 'inline', :inline do
    let!(:message) { { 'foo' => 'bar' } }
    let!(:processor) { ->(m) { messages << m.raw_body } }

    before { subject }

    it { should be_connected }

    it 'should terminate' do
      expect { subject.terminate }.to change(subject, :connected?).to(false)
    end

    describe 'when the processor returns true' do
      it 'processes and removes messages' do
        expect { FastlyNsq::Producer.new(topic: topic).write(message) }.to change { messages.size }.by(1)
        expect(messages).to contain_exactly(message)
        expect(subject.messages).to be_empty
      end
    end

    describe 'when the processor returns false' do
      let(:processor) { ->(_) { false } }

      it 'does not remove messages' do
        FastlyNsq::Producer.new(topic: topic).write(message)
        expect { subject.drain }.not_to change { subject.messages.size }
      end
    end
  end
end
