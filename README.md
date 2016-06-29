[![Gem Version](https://badge.fury.io/rb/resugan.svg)](https://badge.fury.io/rb/resugan) [![CircleCI](https://circleci.com/gh/jedld/resugan.svg?style=svg)](https://circleci.com/gh/jedld/resugan)

# Resugan

Simple, powerful and unobstrusive event driven architecture framework for ruby. This gem provides
a base framework in order to build a more powerful event based system on top of it. Events cuts across multiple objects and allows you to cleanly separate business logic to other cross cutting concerns like analytics and logging. Multiple events are consolidated allowing you to efficiently batch related operations together.

Also allows for a customizable backend which enables the use of various evented queuing mechanisms
like redis queue, amazon SQS with minimal changes to your code that generates the events.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'resugan'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install resugan

## Basic Usage

Register listeners, using :

```ruby
  _listener :event1 do |array_of_params|
    puts "hello! event 2 has been called!"
  end

  _listener :hay do |array_of_params|
    puts "hello! someone said hay!"
  end
```

Listeners are basically code that listens to an event, in this case :event1 and :hay.
an array of params equal to the number of times that specific event was captured
will be passed. So if :event1 was called twice, array_of_params will contain 2 elements.

Generate events using _fire and wrap them in a resugan block:

```ruby
resugan {
  puts "I am now going to generate an event"

  _fire :event2

  _fire :hay

  _fire :bam, { some_param: 'param' } # you can pass hashes to add meta to the event
}
```

The _fire method is available inside all objects, however the events won't be
collected unless within the context of a resugan block. The idea is that you
can prepackage a library that fires those events but won't actually
get used until someone specifically listens for it.

Note that events don't have to be fired at the top level of the block, even objects
used inside the block can invoke fire to generate an event.

The two events should fire and should print:

```ruby
hello! event 2 has been called!
hello! someone said hay!
```

Note that your listener will be executed once even if an event has been fired
multiple times. However params will contain the payload of both events. This allows you to batch together requests and efficiently dispatch them as a group.

# Object helpers

Helpers are available to make listening firing events a little bit cleaner:

```ruby
class TestObject
  include Resugan::ObjectHelpers
end
```

This basically allows for the attach_hook to be available

```ruby
class TestObject
  include Resugan::ObjectHelpers

  def method2
    _fire :event1
  end

  def method3
    _fire :event2, param1: "hello"
  end

  attach_hook :method2
  attach_hook :method3, namespace: "namespace1"
end
```

What this does is it essentially wraps the specified methods inside a resugan block.

Please see spec/resugan_spec.rb for more examples and details.

## namespaces

Resugan supports namespaces, allowing you to group listeners and trigger them separately

```ruby
  _listener :event1, namespace: "group1" do |array_of_params|
    puts "hello! event 2 has been called!"
  end

  _listener :event1, namespace: "group2" do |array_of_params|
    puts "hello! someone said hay!"
  end

  _listener :log, namespace: %w(group1 group2) do |array_of_params|
    array_of_params.each {
      puts "listener that belongs to 2 namespaces"
    }
  end

  resugan "group1" do
    _fire :event1
    _fire :log
  end

  resugan "group2" do
    _fire :event1
    _fire :log
  end
```

Behavior is as expected. Events under group1 will only be handled by listeners under group1 and so on.

The above should print:

```
hello! event 2 has been called!
listener that belongs to 2 namespaces
hello! someone said hay!
listener that belongs to 2 namespaces
```
## Unique Listeners

the _listener always creates a new listener for an event, so if it so happens that
the code that creates those listeners gets executed again it will create another one.
if you want to make sure that listener only gets executed once you can pass an id
option:

```ruby
listener :event1, id: 'no_other_listener_like_this' do |array|
 # some code that gets executed
end
```

## Customizing the Event dispatcher

The way events are consumed is entirely customizable. You can register your own event dispatcher:

```ruby
class MyCustomerDispatcher
  def dispatch(namespace, events)
    events.each do |k,v|
      Resugan::Kernel.invoke(namespace, k, v)
    end
  end
end
```

You need to implement your own dispatch method, captured events are passed as
parameters.

You can then set it as the default dispatcher:

```ruby
  Resugan::Kernel.set_default_dispatcher(MyCustomerDispatcher)
```

Or assign it to a specific namespace:

```ruby
  Resugan::Kernel.register_dispatcher(MyCustomerDispatcher, 'CustomGroup')
```

This allows you to use various queue backends per namespace, like resugan-worker for example.

### Debugging

Sometimes you need to track where events are fired. You can do so by enabling line tracing:

```ruby
  Resugan::Kernel.enable_line_trace true
```

Line source should now be passed as params everytime you fire an event. You can also
view it by dumping a resugan context.

```ruby
puts(resugan {
  _fire :event1
}.dump)
```

```ruby
{:event1=>[{:params=>{:_source=>"/Users/jedld/workspace/resugan/spec/resugan_spec.rb:144:in `block (5 levels) in <top (required)>'"}}]}
```

### Using Resugan::Engine::MarshalledInlineDispatcher

By default, resugan uses the Resugan::Engine::InlineDispatcher as the default dispatcher for
all namespaces. For performance reasons, params passed to the _fire method are passed as is, but there are
times when you want to simulate params that are passed using JSON.parse as is the case
when using a custom dispatcher that uses redis (see resugan-worker). In this case you may set MarshalledInlineDispatcher
as the default dispatcher for test and development environment instead (e.g. rails):

```ruby
Resugan::Kernel.set_default_dispatcher(Resugan::Engine::MarshalledInlineDispatcher) if Rails.env.development? || Rails.env.test?
```

Related Projects
=================

Below are projects that extend resugan.

### Resugan Worker

A project that wraps resugan listeners to be consumed using an external worker. Think of this as a redis queue backend.
Can also be used as a sample on how to extend resugan.

https://github.com/jedld/resugan-worker

## Similar Projects

wisper (https://github.com/krisleech/wisper) - An excellent gem that focuses on a pub-sub model. Though its global listeners somehow have the same effect though in a syntactically different way than resugan.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/resugan. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
