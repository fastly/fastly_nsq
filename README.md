# fastly_nsq [![Build Status](https://travis-ci.org/fastly/fastly_nsq.svg?branch=master)](https://travis-ci.org/fastly/fastly_nsq)

NSQ adapter and testing objects
for using the NSQ messaging system
in your Ruby project.

This library is intended
to facilitate publishing and consuming
messages on an NSQ messaging queue.

We also include fakes
to make testing easier.

This library is dependent
on the [`nsq-ruby`] gem.

[`nsq-ruby`]: https://github.com/wistia/nsq-ruby

Please use [GitHub Issues] to report bugs.

[GitHub Issues]: https://github.com/fastly/fastly_nsq/issues

**[Documentation](https://www.rubydoc.info/gems/fastly_nsq)**

## Install

`fastly_nsq` is a Ruby Gem
tested against Rails `>= 4.2`
and Ruby `>= 2.1.8`.

To get started,
add `fastly_nsq` to your `Gemfile`
and `bundle install`.

## Usage

### `FastlyNsq::Producer`

This is a class
which provides an adapter to the
fake and real NSQ producers.
These are used to
write messages onto the queue:

```ruby
message_data = {
  "data" => {
    "key" => "value"
  }
}

producer = FastlyNsq::Producer.new(
  nsqd: ENV.fetch('NSQD_TCP_ADDRESS'),
  topic: topic,
)

producer.write(message_data.to_json)
```
The mock/real strategy used
can be switched
by requiring the test file and configuring the mode.

```ruby
require 'fastly_nsq/testing'
FastlyNsq::Testing.enabled? #=> true
FastlyNsq::Testing.disabled? #=> false

producer = FastlyNsq::Producer.new(topic: topic)
listener = FastlyNsq::Listener.new(topic: topic, channel: channel, processor: ->(m) { puts 'got: '+ m.body })

FastlyNsq::Testing.fake! # default, messages accumulate on the listeners

producer.write '{"foo":"bar"}'
listener.messages.size #=> 1

FastlyNsq::Testing.reset!  # remove all accumulated messages

listener.messages.size #=> 0

producer.write '{"foo":"bar"}'
listener.messages.size #=> 1

listener.drain
#  got: {"foo"=>"bar"}
listener.messages.size #=> 0

FastlyNsq::Testing.inline! # messages are processed as they are produced
producer.write '{"foo":"bar"}'
#  got: {"foo"=>"bar"}
listener.messages.size #=> 0

FastlyNsq::Testing.disable! # do it live
FastlyNsq::Testing.enable!  # re-enable testing mode
```

### `FastlyNsq::Consumer`
This is a class
which provides an adapter to the
fake and real NSQ consumers.
These are used to
read messages off of the queue:

```ruby
consumer = FastlyNsq::Consumer.new(
  topic: 'topic',
  channel: 'channel'
)

consumer.size #=> 1
message = consumer.pop
message.body #=> "{ 'data': { 'key': 'value' } }"
message.finish
consumer.size #=> 0
consumer.terminate
```

### `FastlyNsq::Listener`

To process the next message on the queue:

```ruby
topic     = 'user_created'
channel   = 'my_consuming_service'
processor = MessageProcessor

FastlyNsq::Listener.new(topic: topic, channel: channel, processor: processor)
```

This will send messages through `FastlyNsq.manager.pool`
off of the queue
and send the JSON text body
to `MessageProcessor.call(message)`.

Specify a topic priority by providing a number (default is 0)

```ruby
topic     = 'user_created'
channel   = 'my_consuming_service'
processor = MessageProcessor
priority  = 1 # a little higher

FastlyNsq::Listener.new(topic: topic, channel: channel, processor: processor, priority: priority)
```

### `FastlyNsq::CLI`

To help facilitate running the `FastlyNsq::Listener` in a blocking fashion
outside your application, a `CLI` and bin script [`fastly_nsq`](bin/fastly_nsq)
are provided.

This can be setup ahead of time by calling `FastlyNsq.configure` and passing block.

```ruby
# config/fastly_nsq.rb
FastlyNsq.configure do |config|
  config.channel = 'fnsq'
  config.logger = Logger.new
  config.preprocessor = ->(_) { FastlyNsq.logger.info 'PREPROCESSESES' }

  config.max_attempts = 20
  config.max_req_timeout = (60 * 60 * 4 * 1_000) # 4 hours
  config.max_processing_pool_threads = 10

  lc.listen 'posts', ->(m) { puts "posts: #{m.body}" }
  lc.listen 'blogs', ->(m) { puts "blogs: #{m.body}" }, priority: 3
end
```

An example of using the cli:

```bash
./bin/fastly_nsq -r config/fastly_nsq.rb -L ./test.log -P ./fastly_nsq.pid -v -d -t 4 -c 10
```

### `FastlyNsq::Messenger`

Wrapper around a producer for sending messages and persisting producer objects.

```ruby
FastlyNsq::Messenger.deliver(message: msg, topic: 'my_topic', originating_service: 'my service')
```

You can also optionally pass custom metadata.

```ruby
FastlyNsq::Messenger.deliver(message: msg, topic: 'my_topic', originating_service: 'my service', meta: { test: 'test' })
```

This will use a FastlyNsq::Producer for the given topic or create on if it isn't
already persisted. Then it will write the passed message to the queue. If you don't set
the originating service it will use `unknown`

You can also set the originating service for all `deliver` calls:

```ruby
FastlyNsq::Messenger.originating_service = 'some awesome service'
```

`FastlyNsq::Messenger` also spuports delivering multiple message at once and will
use the NSQ `mpub` directive under the hood.

```ruby
FastlyNsq::Messenger.deliver_multi(messages: array_of_msgs, topic: 'my_topic')
```

`FastlyNsq::Messenger` can also be used to manage Producer connections

```ruby
# get a producer:
producer = FastlyNsq::Messenger.producer_for(topic: 'hot_topic')

# get a hash of all persisted producers:
producers = FastlyNsq::Messenger.producers

# terminate a producer
FastlyNsq::Messenger.terminate_producer(topic: 'hot_topic')

# terminate all producers
FastlyNsq::Messenger.terminate_all_producers
```

### `FastlyNsq::Http`

Wrappers around `nsqd` and `nsqlookupd` http api's described here:
* [NSQD API](http://nsq.io/components/nsqd.html)
* [NSQLOOKUPD API](http://nsq.io/components/nsqlookupd.html)

#### `Nsqd`

Implements most of the Nsqd api.

Example usage:
```ruby
FastlyNsq::Http::Nsqd.ping
FastlyNsq::Http::Nsqd.create_channel(topic: 'foo', channel: 'bar')
FastlyNsq::Http::Nsqd.stats(topic: 'foo', format: '')
```

TODO:
1. Debug endpoints (`/debug/*`)
2. Config PUT (`/config/nsqlookupd_tcp_address`)
3. Correct Handling of `mpub` `binary` mode

#### `Nsqlookupd`

Implements all of the Nsqlookupd api.

Example usage:
```ruby
FastlyNsq::Http::Nsqlookupd.nodes
FastlyNsq::Http::Nsqlookupd.lookup(topic: 'foo')
```

### Testing

`FastlyNsq` provides a test mode and a helper class to make testing easier.

In order to test classes that use FastlyNsq without having real connections
to NSQ:

```ruby
require 'fastly_nsq/testing'

RSpec.configure do |config|
  config.before(:each) do
    FastlyNsq::Testing.fake!
    FastlyNsq::Testing.reset!
  end
end
```

To test processor classes you can create test messages:

```ruby
test_message = FastlyNsq::Testing.message(data: { 'count' => 123 })

My::ProcessorKlass.call(test_message)

expect(some_result)
```

## Configuration

### Environment Variables

The URLs for the various
NSQ endpoints are expected
in `ENV` variables.

Below are the required variables
and sample values for using
stock NSQ on OS X,
installed via Homebrew:

```shell
NSQD_TCP_ADDRESS='127.0.0.1:4150'
NSQD_HTTP_ADDRESS='127.0.0.1:4151'
NSQLOOKUPD_TCP_ADDRESS='127.0.0.1:4160'
NSQLOOKUPD_HTTP_ADDRESS='127.0.0.1:4161, 10.1.1.101:4161'
```

See the [`.sample.env`](examples/.sample.env) file
for more detail.

## Development

The fastest way to get up and running for development is to use
the Docker container provided by Docker Compose:

* Clone: `git clone https://github.com/fastly/fastly_nsq.git`
* `cd fastly_nsq`
* run `bundle install`
* run `docker-compose up -d`
* `rake spec`

You will still need the `ENV` variables as defined above.

## Contributors

* Adarsh Pandit ([@adarsh](https://github.com/adarsh))
* Thomas O'Neil ([@alieander](https://github.com/alieander))
* Joshua Wehner ([@jaw6](https://github.com/jaw6))
* Lukas Eklund  ([@leklund](https://github.com/leklund))
* Josh Lane     ([@lanej](https://github.com/lanej))
* Hassan Shahid ([@set5think](https://github.com/set5think))

## Acknowledgements

* Documentation inspired by [Steve Losh's "Teach Don't Tell"](http://stevelosh.com/blog/2013/09/teach-dont-tell/) post.
* Thanks to Wistia for [`nsq-ruby`](https://github.com/wistia/nsq-ruby).

## Copyright

Copyright (c) 2016 [Fastly, Inc](https://fastly.com) under an MIT license.

See [LICENSE.txt](LICENSE.txt) for details.
