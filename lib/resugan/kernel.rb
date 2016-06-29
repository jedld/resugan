module Resugan
  class Kernel
    # flag to log the line source where a fire was executed
    def self.enable_line_trace(enable)
      @enable = enable
    end

    def self.line_trace_enabled?
      @enable || false
    end

    def self.set_default_dispatcher(dispatcher)
      @default_dispatcher ||= dispatcher.new
    end

    def self.default_dispatcher
      @default_dispatcher || Resugan::Engine::InlineDispatcher.new
    end

    def self.dispatcher_for(namespace = '')
      @dispatchers = {} unless @dispatchers
      @dispatchers[namespace] || default_dispatcher
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
      @_listener = {} unless @_listener

      return self if listener_id && @listener_ids["#{namespace}_#{listener_id}"]

      event = "#{namespace}_#{event}".to_sym

      unless @_listener[event]
        @_listener[event] = [block]
      else
        @_listener[event] << block
      end

      @listener_ids["#{namespace}_#{listener_id}"] = block if listener_id

      self
    end

    def self.invoke(namespace, event, payload = [])
      event = "#{namespace}_#{event}".to_sym
      if @_listener && @_listener[event]
        @_listener[event].each do |_listener|
          _listener.call(payload.map { |p| p[:params] })
        end
      end
    end

    def self.listeners
      @_listener
    end

    def self.clear
      @listener_ids.clear if @listener_ids
      @_listener.clear if @_listener
    end
  end
end
