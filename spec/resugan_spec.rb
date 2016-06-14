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

describe Resugan do
  before :each do
    Resugan::Kernel.clear
  end

  it 'captures fire calls' do
    Resugan::Kernel.register(:event2, ->(params) {
          TestObject.new.method1(params)
      })

    expect_any_instance_of(TestObject).to receive(:method1)

    resugan {
      fire :event1
      fire :event1
      fire :event2, param1: "hello"
    }
  end

  it 'supports method hooks' do
    Resugan::Kernel.register(:event1, ->(params) {
          TestObject.new.method1(params)
      })

    Resugan::Kernel.register_with_namespace("namespace1", :event2, ->(params) {
          TestObject.new.methodx(params)
          expect(params[0][:param1]).to eq "hello"
      })


    expect_any_instance_of(TestObject).to receive(:method1)
    expect_any_instance_of(TestObject).to receive(:methodx)

    TestObject.new.method2
    TestObject.new.method3
  end

  it 'supports multiple namespaces' do
    Resugan::Kernel.register_with_namespace("namespace1", :event2, ->(params) {
          TestObject.new.method1(params)
          expect(params[0][:param1]).to eq "hello"
      })

    expect_any_instance_of(TestObject).to receive(:method1)

    resugan "namespace1" do
      fire :event1
      fire :event3
      fire :event2, param1: "hello"
    end
  end
end
