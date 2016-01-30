# fastly_nsq

NSQ adapter and testing objects
for using the NSQ messaging system
in your Ruby project.

This library is intended
to facilitate publishing and consuming
messages on an NSQ messaging queue.

We also include a fake queue
to make testing easier.

This library is dependent
on the [`nsq-ruby`] gem.

[`nsq-ruby`]: https://github.com/wistia/nsq-ruby

Please use [GitHub Issues] to report bugs.

[GitHub Issues]: https://github.com/fastly/fastly_nsq/issues


## Install

`fastly_nsq` is a Ruby Gem
tested against Rails `>= 4.2`
and Ruby `>= 2.0`.

To get started,
add `fastly_nsq` to your `Gemfile`
and `bundle install`.

The gem includes the following objects:

### [`MessageQueue`]

This is an adapter class
which takes a required `topic` string
and provides entry points
for the queue's message producer and consumer classes.

The queue strategy used
can be switched
by adding an environment variable
to your application:

```ruby
if ENV['FAKE_QUEUE'] == true
  FakeMessageQueue
else
  NsqMessageQueue
end
```

[`MessageQueue`]: lib/fastly_nsq/message_queue.rb


### [`NsqMessageQueue`]

This strategy
creates a connection
to `nsq-ruby`'s
`Nsq::Producer` and `Nsq::Consumer` classes.

[`NsqMessageQueue`]: lib/fastly_nsq/nsq_message_queue.rb


### [`FakeMessageQueue`]

This strategy
mocks the connection
to NSQ for testing purposes.

It adheres to the same API
as `NsqMessageQueue`.

[`FakeMessageQueue`]: lib/fastly_nsq/fake_message_queue.rb


*IMPORTANT NOTE:* You must create your own `MessageProcessor` class
for this gem to work in your application.

See more information below.


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
  def initialize(message)
    @message = message
  end

  def start
    # Do things with the message. It's JSON body is accessible by @message.body.

    # Finish the message to let the queue know it is complete like so:
    @message.finish
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

### Live vs. Fake

In the gem's test suite,
the fake message queue is used.

If you would like to force
use of the real NSQ adapter,
ensure `FAKE_QUEUE` is *not* set to anything in `ENV`.

When you are developing your application,
it is recommended to
start by using the fake queue:

```shell
FAKE_QUEUE=true
```

Also note that during gem tests,
we are aliasing `MessageProcessor` to `SampleMessageProcessor`.
You can also refer to the latter
as an example of how
you might write your own processor.


## How to Use the Gem
### Publishing Messages

To publish a message on the queue:

```ruby
message_data = {
  "event_type": "heartbeat",
  "data": {
    "service": "Northstar"
  }
}
message_string = message_data.to_json
producer = MessageQueue.new(topic: 'northstar').producer
producer.write(message_string)
```

### Consuming Messages

To consume the next message on the queue:

```ruby
# TBD!!!!!
# Waiting until I put the `QueueListener` stuff in here...
```

## Additional Reference

## Acknowledgements

* Documentation inspired by [Steve Losh's "Teach Don't Tell"] post.
* Thanks to Wistia for `nsq-ruby`.

[Steve Losh's "Teach Don't Tell"]: http://stevelosh.com/blog/2013/09/teach-dont-tell/


## Copyright

Copyright (c) 2016 Fastly, Inc under an MIT license.

See [LICENSE.txt](LICENSE.txt) for details.
