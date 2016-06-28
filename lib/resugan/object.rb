class Object
  def resugan(namespace = '', &block)
    current_thread = Thread.current
    current_thread.push_resugan_context(namespace)

    block.call

    context = current_thread.pop_resugan_context
    context.invoke
  end

  def _fire(event, params = {})
    current_thread = Thread.current
    if current_thread.resugan_context
      current_thread.resugan_context.register(event, params)
    end
  end

  def _listener(event, options = {}, &block)
    Resugan::Kernel.register_with_namespace(options[:namespace], event, options[:id], ->(params) {
        block.call(params)
      })
  end
end
