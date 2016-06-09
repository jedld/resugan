module Resugan
  class Kernel
    def self.register(event, block)
      @listener = {} unless @listener

      event = event.to_sym

      unless @listener[event]
        @listener[event] = [block]
      else
        @listener[event] << block
      end

      self
    end

    def self.invoke(event, payload = [])
      if @listener[event]
        @listener[event].each do |listener|
          listener.call(payload.map { |p| p[:params] })
        end
      end
    end
  end
end
