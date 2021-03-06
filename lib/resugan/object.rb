class Object
  def resugan(namespace = '', &block)
    namespace ||= ''
    current_thread = Thread.current
    current_thread.push_resugan_context(namespace)
    begin
      block.call
    ensure
      context = current_thread.pop_resugan_context
    end
    context
  end

  def resugan!(namespace = '', &block)
    namespace ||= ''
    current_thread = Thread.current
    current_thread.push_resugan_context(namespace, true)
    begin
      block.call
    ensure
      context = current_thread.pop_resugan_context(true)
    end
    context
  end

  def _fire(event, params = {})
    params[:_source] = caller[0] if Resugan::Kernel.line_trace_enabled?

    current_thread = Thread.current
    if current_thread.resugan_context
      current_thread.resugan_context.register(event, params)
    else
      puts "WARN: #{event} called in #{caller[0]} but was not inside a resugan {} block" if Resugan::Kernel.warn_no_context_events?
    end
  end

  def _listener(event, options = {}, &block)
    Resugan::Kernel.register_with_namespace(options[:namespace], event, options[:id], ->(params) {
        block.call(params)
      })
  end

  def _listener!(event, options = {}, &block)
    Resugan::Kernel.register_with_namespace(options[:namespace], event, options[:id] || caller[0], ->(params) {
        block.call(params)
      })
  end
end
