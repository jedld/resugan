module Resugan
  class Kernel
    def self.register(event, block)
      register_with_namespace("", event, block)
    end

    def self.register_with_namespace(namespace, event, block)
      @listener = {} unless @listener

      event = "#{namespace}_event".to_sym

      unless @listener[event]
        @listener[event] = [block]
      else
        @listener[event] << block
      end

      self
    end

    def self.invoke(namespace, event, payload = [])
      event = "#{namespace}_event".to_sym

      if @listener[event]
        @listener[event].each do |listener|
          listener.call(payload.map { |p| p[:params] })
        end
      end
    end

    def self.clear
      @listener.clear if @listener
    end
  end
end
