module Resugan
  class Config
    attr_accessor :reuse_top_level_context, :warn_no_context_events, :line_trace_enabled, :default_dispatcher

    def initialize
      @reuse_top_level_context = true
      @warn_no_context_events = false
      @line_trace_enabled = false
      @default_dispatcher = Resugan::Engine::InlineDispatcher
    end
  end

  class Kernel
    def self.config
      @config ||= Resugan::Config.new
      if block_given?
        yield @config
      end

      @config
    end

    def self.reuse_top_level_context?
      config.reuse_top_level_context
    end

    def self.warn_no_context_events?
      config.warn_no_context_events
    end

    def self.line_trace_enabled?
      config.line_trace_enabled
    end

    def self.set_default_dispatcher(dispatcher)
      config.default_dispatcher = dispatcher
    end

    def self.default_dispatcher
      config.default_dispatcher
    end

    def self.dispatcher_for(namespace = '')
      @dispatchers = {} unless @dispatchers
      @dispatchers[namespace.to_s] || default_dispatcher.new
    end

    def self.register_dispatcher(dispatcher, namespace = '')
      @dispatchers = {} unless @dispatchers
      @dispatchers[namespace.to_s] = (dispatcher.is_a?(Class) ? dispatcher.new : dispatcher)
    end

    def self.register(event, &block)
      register_with_namespace("", event, block)
    end

    def self.register_with_namespace(namespaces, event_type, listener_id = nil, block)
      @listener_ids = {} unless @listener_ids
      @_listener = {} unless @_listener

      namespaces = namespaces.is_a?(Array) ? namespaces : [namespaces]
      namespaces.each do |n|
        next if listener_id && @listener_ids["#{n}_#{listener_id}"]

        event = "#{n}_#{event_type}".to_sym

        unless @_listener[event]
          @_listener[event] = [block]
        else
          @_listener[event] << block
        end

        @listener_ids["#{n}_#{listener_id}"] = block if listener_id
      end

      self
    end

    def self.invoke(namespace, event, payload = [])
      event = "#{namespace}_#{event}".to_sym
      if @_listener && @_listener[event]
        @_listener[event].each do |_listener|
          _listener.call(payload.map { |p| p[:params] || p['params'] })
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
