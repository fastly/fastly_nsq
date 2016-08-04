require 'spec_helper'
require 'json'

RSpec.describe FastlyNsq::Message do
  let(:body)      { {'data' => 'goes here', 'other_field' => 'is over here'} }
  let(:json_body) { body.to_json }
  subject         { FastlyNsq::Message.new json_body }
  
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
    expect("#{subject}").to eq(json_body)
  end
end