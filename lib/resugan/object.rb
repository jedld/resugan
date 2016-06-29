class Object
  def resugan(namespace = '', &block)
    current_thread = Thread.current
    current_thread.push_resugan_context(namespace)
    begin
      block.call
    ensure
      context = current_thread.pop_resugan_context
      context.invoke
    end
    context
  end

  def _fire(event, params = {})
    params[:_source] = caller[0] if Resugan::Kernel.line_trace_enabled?

    current_thread = Thread.current
    if current_thread.resugan_context
      current_thread.resugan_context.register(event, params)
    else
      puts "WARN: #{event} called in #{caller[0]} but was not inside a resugan {} block" if Resugan::Kernal.warn_no_context_events?
    end
  end

  def _listener(event, options = {}, &block)
    Resugan::Kernel.register_with_namespace(options[:namespace], event, options[:id], ->(params) {
        block.call(params)
      })
  end
end
