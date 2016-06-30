require 'spec_helper'

class TestObject
  include Resugan::ObjectHelpers

  def method1(params)
  end

  def methodx(params)
  end

  def method2
    _fire :event1
  end

  def method3
    _fire :event2, param1: "hello"
  end

  attach_hook :method2
  attach_hook :method3, namespace: "namespace1"
end

module Resugan
  module Engine
    class CustomDispatcher
      def dispatch(namespace, events)
        events.collect do |k,v|
          "#{k},#{v}"
        end
      end
    end
  end
end

describe Resugan do
  before :each do
    Resugan::Kernel.clear
    Resugan::Kernel.set_default_dispatcher Resugan::Engine::MarshalledInlineDispatcher
  end

  it 'captures _fire calls' do
    _listener :event2 do |params|
      TestObject.new.method1(params)
    end

    _listener :event3 do |params|
      TestObject.new.methodx(params)
    end

    expect_any_instance_of(TestObject).to receive(:method1)
    expect_any_instance_of(TestObject).to receive(:methodx)

    resugan {
      _fire :event1
      _fire :event1
      _fire :event2, param1: "hello"
      _fire "event3" # string or symbol doesn't really matter
    }
  end

  it 'supports method hooks' do
    _listener :event1 do |params|
      TestObject.new.method1(params)
    end

    _listener :event2, namespace: "namespace1" do |params|
      TestObject.new.methodx(params)
      expect(params[0]['param1']).to eq "hello"
    end

    expect_any_instance_of(TestObject).to receive(:method1)
    expect_any_instance_of(TestObject).to receive(:methodx)

    TestObject.new.method2
    TestObject.new.method3
  end

  context "namespaces" do
    it 'supports multiple namespaces' do
      _listener :event2, namespace: "namespace1" do |params|
        TestObject.new.method1(params)
        expect(params[0]['param1']).to eq "hello"
      end

      expect_any_instance_of(TestObject).to receive(:method1)

      resugan "namespace1" do
        _fire :event1
        _fire :event3
        _fire :event2, param1: "hello"
      end
    end

    it 'supports multiple namespaces per listener' do
      @counter = 0
      _listener :event2, namespace: ['namespace1', 'namespace2'] do |params|
        params.each {  @counter += 1 }
      end

      resugan("namespace1") do
        _fire :event2, param1: "hello"
      end

      resugan("namespace2") do
        _fire :event2, param2: "Hi"
      end

      resugan { _fire :event2 }

      expect(@counter).to eq 2
    end
  end

  it 'supports multiple hooks on one event' do
    expect_any_instance_of(TestObject).to receive(:method1)
    expect_any_instance_of(TestObject).to receive(:methodx)

    _listener :event1 do |params|
      TestObject.new.method1(params)
    end

    _listener :event1 do |params|
      TestObject.new.methodx(params)
    end

    resugan {
      _fire :event1
    }
  end

  it 'if id is given, _listener with that id is only allowed to be registered once' do
    _listener :event1, id: 'cat' do |params|
      TestObject.new.method1(params)
    end

    _listener :event1, id: 'cat' do |params|
      TestObject.new.methodx(params)
      fail
    end

    # _listener! prevents a block from being defined twice
    count = 0
    2.times do |i|
      _listener! :event2 do |params|
        count += 1
      end
    end

    expect_any_instance_of(TestObject).to receive(:method1)

    resugan {
      _fire :event1
      _fire :event2
    }

    expect(count).to eq(1)
  end

  context "behavior of return and exceptions" do
    it "Always ensures that events are consumed even if the block returns" do
      @must_be_true = false

      _listener :event1, id: 'xxx' do |params|
        @must_be_true = true
      end

      begin
        resugan {
          _fire :event1
          raise "error"
        }

        expect(true).to eq false
      rescue RuntimeError
      end

      expect(@must_be_true).to be
    end
  end

  context "customizations" do
    it "allow the default dispatcher to be modified" do
      Resugan::Kernel.register_dispatcher(Resugan::Engine::CustomDispatcher, "namespacex")

      expect_any_instance_of(Resugan::Engine::CustomDispatcher).to receive(:dispatch).with('namespacex',
        {:event1=>[{:params=>{}}, {:params=>{}}], :event2=>[{:params=>{:param1=>"hello"}}]})

      resugan "namespacex" do
        _fire :event1
        _fire :event1
        _fire :event2, param1: "hello"
      end
    end

    context "debugging" do
      around :each do |example|
        Resugan::Kernel.enable_line_trace true
        example.run
        Resugan::Kernel.enable_line_trace false
      end

      it "a resugan block returns a context which can be dumped" do
        context_dump = resugan {
          _fire :event1
        }.dump

        expect(context_dump[:event1].size).to eq 1
      end

      it "allows line source tracing to be enabled" do
        context_dump = resugan {
          _fire :event1
          _fire :event1
          _fire :event2, param1: "hello"
        }.dump

        expect(context_dump.size).to eq 2 #two events
        expect(context_dump[:event2].first[:params][:_source]).to match /spec\/resugan_spec\.rb\:/
      end
    end
  end
end
