require 'spec_helper'

class TestObject
  def method1(params)
    fire :event3
  end
end

describe Resugan do
  it 'captures fire calls' do
    Resugan::Kernel.register(:event1, ->(params) {
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
end
