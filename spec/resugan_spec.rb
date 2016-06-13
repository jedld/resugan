require 'spec_helper'

class TestObject
  def method1(params)
  end
end

describe Resugan do
  before :each do
    Resugan::Kernel.clear
  end

  it 'captures fire calls' do
    Resugan::Kernel.register(:event2, ->(params) {
          puts "Hello world!"
          TestObject.new.method1(params)
      })

    expect_any_instance_of(TestObject).to receive(:method1)

    resugan {
      fire :event1
      fire :event1
      fire :event2, param1: "hello"
    }
  end

  it 'supports multiple namespaces' do
    Resugan::Kernel.register_with_namespace("namespace1", :event1, ->(params) {
          puts "Hello world!"
          TestObject.new.method1(params)
      })

    expect_any_instance_of(TestObject).to receive(:method1)

    resugan "namespace1" do
      fire :event1
      fire :event3
      fire :event2, param1: "hello"
    end
  end
end
