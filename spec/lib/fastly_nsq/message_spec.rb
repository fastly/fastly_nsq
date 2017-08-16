require 'spec_helper'
require 'json'

RSpec.describe FastlyNsq::Message do
  let(:nsq_message) { double 'Nsq::Message', body: json_body, attempts: nil, finish: nil, requeue: nil, touch: nil, timestamp: nil }
  let(:body)        { { 'data' => 'goes here', 'other_field' => 'is over here' } }
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

  it 'aliases raw_body to to_s' do
    expect(subject.to_s).to eq(json_body)
  end

  it 'delegates methods to the nsq_message object' do
    %w(attempts finish requeue touch timestamp).each do |method|
      expect(nsq_message).to receive(method)

      subject.send(method)
    end
  end
end
