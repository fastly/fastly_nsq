# frozen_string_literal: true

require 'spec_helper'
require 'fastly_nsq/http/nsqd'

RSpec.describe FastlyNsq::Http::Nsqd, :webmock do
  let(:base_uri) { 'http://example.com' }

  it 'makes simple get requests' do
    %w[ping info config/nsqlookupd_tcp_addresses].each do |api|
      url = "#{base_uri}/#{api}"
      stub_request(:get, url)
      FastlyNsq::Http::Nsqd.send(api.tr('/', '_').to_sym, base_uri: base_uri)

      expect(a_request(:get, url)).to have_been_requested
    end
  end

  describe 'stats' do
    it 'can fetch stats' do
      url = "#{base_uri}/stats?topic=lol&channel=foo&format=json"
      stub_request(:get, url)
      data = { topic: 'lol', channel: 'foo', format: 'json' }

      FastlyNsq::Http::Nsqd.stats(topic: 'lol', channel: 'foo', base_uri: base_uri)

      expect(a_request(:get, url).with(query: data)).to have_been_requested
    end

    it 'raises InvaildFormatError if provided format is not in list' do
      expect do
        FastlyNsq::Http::Nsqd.stats(format: 'foo')
      end.to raise_error(FastlyNsq::Http::Nsqd::InvalidFormatError)
    end
  end

  it 'can publish messages' do
    url = "#{base_uri}/pub?topic=lol&defer=999"
    stub_request(:post, url)
    data = { topic: 'lol', defer: 999 }

    FastlyNsq::Http::Nsqd.pub(topic: 'lol', defer: 999, message: 'SOMETHING', base_uri: base_uri)

    expect(a_request(:post, url).with(query: data, body: 'SOMETHING')).to have_been_requested
  end

  it 'can publish multiple messages' do
    url = "#{base_uri}/mpub?topic=lol&binary=false"
    stub_request(:post, url)
    data = { topic: 'lol' }
    body = "ONE MESSAGE\nTWO MESSAGE\nRED MESSAGE\nBLUE MESSAGE"

    FastlyNsq::Http::Nsqd.mpub(topic: 'lol', message: body, base_uri: base_uri)

    expect(a_request(:post, url).with(query: data, body: body)).to have_been_requested
  end

  it 'can create, delete, empty, pause and unpause topics and channels' do
    verbs = %w[create delete empty pause unpause]

    verbs.each do |verb|
      url = "#{base_uri}/topic/#{verb}?topic=lol"
      stub_request(:post, url)
      data = { topic: 'lol' }

      FastlyNsq::Http::Nsqd.send("topic_#{verb}".to_sym, topic: 'lol', base_uri: base_uri)

      expect(a_request(:post, url).with(query: data)).to have_been_requested

      url = "#{base_uri}/channel/#{verb}?topic=lol&channel=foo"
      stub_request(:post, url)
      data = { topic: 'lol', channel: 'foo' }

      FastlyNsq::Http::Nsqd.send("channel_#{verb}".to_sym, topic: 'lol', channel: 'foo', base_uri: base_uri)

      expect(a_request(:post, url).with(query: data)).to have_been_requested
    end
  end
end
