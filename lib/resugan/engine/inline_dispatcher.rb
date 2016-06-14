module Resugan
  module Engine
    class InlineDispatcher
      def dispatch(namespace, events)
        events.each do |k,v|
          Resugan::Kernel.invoke(namespace, k, v)
        end
      end
    end
  end
end
