module Resugan
  class Context
    def initialize(namespace = '')
      @namespace = namespace
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
      dispatcher = Resugan::Kernel.dispatcher_for(@namespace)
      dispatcher.dispatch(@namespace, @events)
    end
  end
end
