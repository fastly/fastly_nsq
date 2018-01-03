# frozen_string_literal: true

require 'spec_helper'
require 'json'

RSpec.describe FastlyNsq::Message do
  let(:nsq_message) { double 'Nsq::Message', body: json_body, attempts: nil, finish: nil, requeue: nil, touch: nil, timestamp: nil }
  let(:body)        { { 'data' => 'goes here', 'other_field' => 'is over here', 'meta' => 'meta stuff' } }
  let(:json_body)   { body.to_json }
  subject           { FastlyNsq::Message.new nsq_message }

  it 'preserves original message body as raw_body' do
    expect(subject.raw_body).to eq(json_body)
  end

  it 'presents parsed message body as body' do
    expect(subject.body).to eq(body)
  end

  it 'plucks data as data' do
    expect(subject.data).to eq('goes here')
  end

  it 'plucks meta as meta' do
    expect(subject.meta).to eq(body['meta'])
  end

  it 'aliases raw_body to to_s' do
    expect(subject.to_s).to eq(json_body)
  end

  it 'delegates methods to the nsq_message object' do
    %w[attempts finish requeue touch timestamp].each do |method|
      subject = FastlyNsq::Message.new nsq_message
      expect(nsq_message).to receive(method)

      subject.send(method)
    end
  end

  it 'does not finish if the message was requeued' do
    expect(nsq_message).to receive(:requeue).with(1000)
    expect(nsq_message).not_to receive(:finish)

    subject.requeue(1000)
    subject.finish

    expect(subject.managed).to eq(:requeued)
  end

  it 'does not requeue if the message was finished' do
    expect(nsq_message).to receive(:finish)
    expect(nsq_message).not_to receive(:requeue)

    subject.finish
    subject.requeue

    expect(subject.managed).to eq(:finished)
  end
end
