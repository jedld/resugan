module Resugan
  class Context
    def initialize
      @events = {}
    end

    def register(event, params = {})
      event = event.to_sym
      payload = { params: params }
      if @events[event]
        @events[event] << payload
      else
        @events[event] = [payload]
      end
    end

    def invoke
      @events.each do |k,v|
        puts "fire #{k}"
        Resugan::Kernel.invoke(k, v)
      end
    end
  end
end
