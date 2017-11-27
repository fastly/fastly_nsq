# frozen_string_literal: true

require 'spec_helper'
require 'fastly_nsq/http/nsqlookupd'

RSpec.describe FastlyNsq::Http::Nsqlookupd do
  let(:base_uri) { 'http://example.com' }

  it 'makes simple get requests' do
    %w[topics nodes ping info].each do |api|
      url = "#{base_uri}/#{api}"
      stub_request(:get, url)
      FastlyNsq::Http::Nsqlookupd.send(api.to_sym, base_uri: base_uri)

      expect(a_request(:get, url)).to have_been_requested
    end
  end

  it 'can lookup producers for a topic' do
    url = "#{base_uri}/lookup?topic=lol"
    stub_request(:get, url)
    data = { topic: 'lol' }

    FastlyNsq::Http::Nsqlookupd.lookup(topic: 'lol', base_uri: base_uri)

    expect(a_request(:get, url).with(query: data)).to have_been_requested
  end

  it 'can lookup channels for a topic' do
    url = "#{base_uri}/channels?topic=lol"
    stub_request(:get, url)
    data = { topic: 'lol' }

    FastlyNsq::Http::Nsqlookupd.channels(topic: 'lol', base_uri: base_uri)

    expect(a_request(:get, url).with(query: data)).to have_been_requested
  end

  it 'can delete a topic' do
    url = "#{base_uri}/delete_topic?topic=lol"
    stub_request(:get, url)
    data = { topic: 'lol' }

    FastlyNsq::Http::Nsqlookupd.delete_topic(topic: 'lol', base_uri: base_uri)

    expect(a_request(:get, url).with(query: data)).to have_been_requested
  end

  it 'can delete a channel' do
    url = "#{base_uri}/delete_channel?topic=lol&channel=foo"
    stub_request(:get, url)
    data = { topic: 'lol', channel: 'foo' }

    FastlyNsq::Http::Nsqlookupd.delete_channel(topic: 'lol', channel: 'foo', base_uri: base_uri)

    expect(a_request(:get, url).with(query: data)).to have_been_requested
  end

  it 'can tombstone a producer' do
    url = "#{base_uri}/tombstone_topic_producer?topic=lol&node=localhost:8989"
    stub_request(:get, url)
    data = { topic: 'lol', node: 'localhost:8989' }

    FastlyNsq::Http::Nsqlookupd.tombstone_topic_producer(topic: 'lol', node: 'localhost:8989', base_uri: base_uri)

    expect(a_request(:get, url).with(query: data)).to have_been_requested
  end
end
