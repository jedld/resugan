module Resugan
  class Kernel
    def self.dispatcher_for(namespace = '')
      @dispatchers = {} unless @dispatchers
      @dispatchers[namespace] || Resugan::Engine::InlineDispatcher.new
    end

    def self.register_dispatcher(dispatcher, namespace = '')
      @dispatchers = {} unless @dispatchers
      @dispatchers[namespace] = dispatcher
    end

    def self.register(event, &block)
      register_with_namespace("", event, block)
    end

    def self.register_with_namespace(namespace, event, listener_id = nil, block)
      @listener_ids = {} unless @listener_ids
      @listener = {} unless @listener

      return self if listener_id && @listener_ids["#{namespace}_#{listener_id}"]

      event = "#{namespace}_#{event}".to_sym

      unless @listener[event]
        @listener[event] = [block]
      else
        @listener[event] << block
      end

      @listener_ids["#{namespace}_#{listener_id}"] = block if listener_id

      self
    end

    def self.invoke(namespace, event, payload = [])
      event = "#{namespace}_#{event}".to_sym
      if @listener[event]
        @listener[event].each do |listener|
          listener.call(payload.map { |p| p[:params] })
        end
      end
    end

    def self.listeners
      @listener
    end

    def self.clear
      @listener_ids.clear if @listener_ids
      @listener.clear if @listener
    end
  end
end
