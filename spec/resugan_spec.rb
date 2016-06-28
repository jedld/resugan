require 'spec_helper'

class TestObject
  include Resugan::ObjectHelpers

  def method1(params)
  end

  def methodx(params)
  end

  def method2
    fire :event1
  end

  def method3
    fire :event2, param1: "hello"
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
  end

  it 'captures fire calls' do
    listener :event2 do |params|
      TestObject.new.method1(params)
    end

    expect_any_instance_of(TestObject).to receive(:method1)

    resugan {
      fire :event1
      fire :event1
      fire :event2, param1: "hello"
    }
  end

  it 'supports method hooks' do
    listener :event1 do |params|
      TestObject.new.method1(params)
    end

    listener :event2, namespace: "namespace1" do |params|
      TestObject.new.methodx(params)
      expect(params[0][:param1]).to eq "hello"
    end

    expect_any_instance_of(TestObject).to receive(:method1)
    expect_any_instance_of(TestObject).to receive(:methodx)

    TestObject.new.method2
    TestObject.new.method3
  end

  it 'supports multiple namespaces' do
    listener :event2, namespace: "namespace1" do |params|
      TestObject.new.method1(params)
      expect(params[0][:param1]).to eq "hello"
    end

    expect_any_instance_of(TestObject).to receive(:method1)

    resugan "namespace1" do
      fire :event1
      fire :event3
      fire :event2, param1: "hello"
    end
  end

  it 'supports multiple hooks on one event' do
    expect_any_instance_of(TestObject).to receive(:method1)
    expect_any_instance_of(TestObject).to receive(:methodx)

    listener :event1 do |params|
      TestObject.new.method1(params)
    end

    listener :event1 do |params|
      TestObject.new.methodx(params)
    end

    resugan {
      fire :event1
    }
  end

  it 'if id is given, listener with that id is only allowed to be registered once' do
    listener :event1, id: 'cat' do |params|
      TestObject.new.method1(params)
    end

    listener :event1, id: 'cat' do |params|
      TestObject.new.methodx(params)
      fail
    end

    expect_any_instance_of(TestObject).to receive(:method1)

    resugan {
      fire :event1
    }
  end

  context "customizations" do
    it "allow the default dispatcher to be modified" do
      Resugan::Kernel.set_default_dispatcher(Resugan::Engine::CustomDispatcher)

      expect_any_instance_of(Resugan::Engine::CustomDispatcher).to receive(:dispatch).with('',
        {:event1=>[{:params=>{}}, {:params=>{}}], :event2=>[{:params=>{:param1=>"hello"}}]})

      resugan {
        fire :event1
        fire :event1
        fire :event2, param1: "hello"
      }
    end
  end
end
