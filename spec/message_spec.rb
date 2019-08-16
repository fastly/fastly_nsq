# frozen_string_literal: true

require 'spec_helper'
require 'json'

RSpec.describe FastlyNsq::Message do
  let(:nsq_message) { double 'Nsq::Message', body: json_body, attempts: 1, finish: nil, requeue: nil, touch: nil, timestamp: nil, id: nil }
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
    %w[attempts finish requeue touch timestamp id].each do |method|
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

  it 'uses the passed timeout for the requeue timeout' do
    expect(nsq_message).to receive(:requeue).with(1000)

    subject.requeue(1000)
  end

  it 'uses exponential backoff for timeout if none is given' do
    expect(nsq_message).to receive(:requeue).with(46_000..166_000)

    subject.requeue
  end

  it 'uses the FastlyNsq.max_req_timeout it timeout is larger than FastlyNsq.max_req_timeout' do
    expect(nsq_message).to receive(:requeue).with(60 * 60 * 1_000)

    subject.requeue(60 * 60 * 4 * 1_000)
  end
end
