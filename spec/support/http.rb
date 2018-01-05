# frozen_string_literal: true

module SupportHttp
  def message_count(topic)
    topic_stats = JSON.parse(FastlyNsq::Http::Nsqd.stats(topic: topic).body)['topics'].first || {}
    topic_stats['message_count']
  end

  def create_topic(topic)
    FastlyNsq::Http::Nsqd.topic_create(topic: topic).code == 200
  end

  def empty_topic(topic)
    FastlyNsq::Http::Nsqd.topic_empty(topic: topic).code == 200
  end

  def delete_topic(topic)
    FastlyNsq::Http::Nsqd.topic_delete(topic: topic).code == 200
  end

  def delete_channel(topic, channel)
    FastlyNsq::Http::Nsqd.channel_delete(topic: topic, channel: channel).code == 200
  end

  def create_channel(topic, channel)
    FastlyNsq::Http::Nsqd.channel_create(topic: topic, channel: channel).code == 200
  end

  def reset_topic(topic, channel: nil)
    delete_channel(topic, channel) if channel
    delete_topic(topic)
    create_topic(topic)
    create_channel(topic, channel) if channel
  end
end

RSpec.configure { |config| config.include(SupportHttp) }
