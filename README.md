# fastly_nsq [![Build Status](https://travis-ci.org/fastly/fastly_nsq.svg?branch=master)](https://travis-ci.org/fastly/fastly_nsq)

*NOTE: This is a point-release
which is not yet suitable for production.
Use at your own peril.*

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


## Install

`fastly_nsq` is a Ruby Gem
tested against Rails `>= 4.2`
and Ruby `>= 2.1.8`.

To get started,
add `fastly_nsq` to your `Gemfile`
and `bundle install`.

## Usage

*IMPORTANT NOTE:* You must create your own `MessageProcessor` class
for this gem to work in your application.

See more information below.

### `MessageQueue::Producer`

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

producer = MessageQueue::Producer.new(
  nsqd: ENV.fetch('NSQD_TCP_ADDRESS'),
  topic: topic,
)

producer.write(message_data.to_json)
```
The mock/real strategy used
can be switched
by adding an environment variable
to your application:

```ruby
# for the fake
ENV['FAKE_QUEUE'] = true

# for the real thing
ENV['FAKE_QUEUE'] = false
```

### `MessageQueue::Consumer`
This is a class
which provides an adapter to the
fake and real NSQ consumers.
These are used to
read messages off of the queue:

```ruby
consumer = MessageQueue::Consumer.new(
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

As above,
the mock/real strategy used
can be switched by setting the
`FAKE_QUEUE` environment variable appropriately.

### `MessageQueue::Listener`

To process the next message on the queue:

```ruby
topic = 'user_created'
channel = 'my_consuming_service'

MessageQueue::Listener.new(topic: topic, channel: channel).process_next_message
```

This will pop the next message
off of the queue
and send the JSON text body
to `MessageProcessor.new(message_body: message_body, topic: topic).go`.

To initiate a blocking loop to process messages continuously:

```ruby
topic = 'user_created'
channel = 'my_consuming_service'

MessageQueue::Listener.new(topic: topic, channel: channel).go
```

This will block until
there is a new message on the queue,
      pop the next message
      off of the queue
      and send it to `MessageProcessor.new(message_body).go`.

### `MessageQueue::RakeTask`

To help facilitate running the `MessageQueue::Listener` in a blocking fashion
outside your application, a simple `RakeTask` is provided.

NOTE: The rake task expects a
`MessageProcessor.topics` method,
which must return an array of strings
defining the topics to which
we would like to listen and process messages.

The task will listen
to all specified topics,
each in a separate thread.

This task can be added into your `Rakefile` in one of two ways:

Using a block:
```ruby
require 'fastly_nsq/rake_task'

MessageQueue::RakeTask.new(:listen_task) do |task|
  task.channel = 'some_channel'
end

# usage:
`rake listen_task`
```

or using passed in values:
```ruby
require 'fastly_nsq/rake_task'

MessageQueue::RakeTask.new(:listen_task, [:channel])

# usage:
`rake listen_task['my_channel']`
```

Both methods can be used at the same time with the passed in values taking
priority over block assigned values

See the [`Rakefile`](examples/Rakefile) file
for more detail.

### Real vs. Fake

The real strategy
creates a connection
to `nsq-ruby`'s
`Nsq::Producer` and `Nsq::Consumer` classes.

The fake strategy
mocks the connection
to NSQ for testing purposes.
It adheres to the same API
as the real adapter.


## Configuration

### Processing Messages

This gem expects you to create a
new class called `MessageProcessor`
which will process messages
once they are consumed off of the queue topic.

This class needs to adhere to the following API:

```ruby
class MessageProcessor
  # This an instance of NSQ::Message or FakeMessageQueue::Message
  def initialize(message_body)
    @message_body = message_body
  end

  def start
    # Do things
  end

  private

  def message
    JSON.parse(@message_body)
  end
end
```

### Environment Variables

The URLs for the various
NSQ endpoints are expected
in `ENV` variables.

Below are the required variables
and sample values for using
stock NSQ on OS X,
installed via Homebrew:

```shell
BROADCAST_ADDRESS='127.0.0.1'
NSQD_TCP_ADDRESS='127.0.0.1:4150'
NSQD_HTTP_ADDRESS='127.0.0.1:4151'
NSQLOOKUPD_TCP_ADDRESS='127.0.0.1:4160'
NSQLOOKUPD_HTTP_ADDRESS='127.0.0.1:4161'
```

See the [`.sample.env`](examples/.sample.env) file
for more detail.

### Testing Against the Fake

In the gem's test suite,
the fake message queue is used.

If you would like to force
use of the real NSQ adapter,
ensure `FAKE_QUEUE` is set to `false`.

When you are developing your application,
it is recommended to
start by using the fake queue:

```shell
FAKE_QUEUE=true
```

Also be sure call
`FakeMessageQueue.reset!`
before each test in your app to ensure
there are no leftover messages.

Also note that during gem tests,
we are aliasing `MessageProcessor` to `SampleMessageProcessor`.
You can also refer to the latter
as an example of how
you might write your own processor.

## Acknowledgements

* Documentation inspired by [Steve Losh's "Teach Don't Tell"] post.
* Thanks to Wistia for `nsq-ruby`.

[Steve Losh's "Teach Don't Tell"]: http://stevelosh.com/blog/2013/09/teach-dont-tell/


## Copyright

Copyright (c) 2016 Fastly, Inc under an MIT license.

See [LICENSE.txt](LICENSE.txt) for details.
