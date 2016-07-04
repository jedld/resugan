class Thread
  def push_resugan_context(namespace = '')
    @resugan_context_stack ||= []

    namespace = namespace.to_s

    if @resugan_context.nil? || !Resugan::Kernel.reuse_top_level_context?
      @resugan_context = Resugan::Context.new(namespace)
    elsif @resugan_context.namespace != namespace
      @resugan_context = (@resugan_context_stack.reverse.find { |e| e.namespace == namespace }) || Resugan::Context.new(namespace)
    end

    @resugan_context_stack << @resugan_context
  end

  def pop_resugan_context
    _resugan_context = @resugan_context_stack.pop
    @resugan_context = @resugan_context_stack.last

    # depending on option, only invoke if top level
    if Resugan::Kernel.reuse_top_level_context?
      _resugan_context.invoke if @resugan_context_stack.find { |e| e.namespace == _resugan_context.namespace }.nil?
    elsif
      _resugan_context.invoke
    end

    _resugan_context
  end

  def resugan_context
    @resugan_context
  end

  private

  def clear_context
    @resugan_context_stack = []
    @resugan_context
  end
end
