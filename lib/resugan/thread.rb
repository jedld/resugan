class Thread
  def push_resugan_context
    if !@resugan_context
      @resugan_context_stack = []
    end

    @resugan_context = Resugan::Context.new
    @resugan_context_stack << @resugan_context
  end

  def pop_resugan_context
    @resugan_context = @resugan_context_stack.pop
  end

  def resugan_context
    @resugan_context
  end
end
