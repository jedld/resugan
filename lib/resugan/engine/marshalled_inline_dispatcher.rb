module Resugan
  module Engine
    class MarshalledInlineDispatcher
      def dispatch(namespace, events)
        marshalled_events = []
        events.each do |k, v|
          marshalled_events << { event: k, args: v }.to_json
        end

        marshalled_events.each do |event|
          unmarshalled_event = JSON.parse(event)
          Resugan::Kernel.invoke(namespace, unmarshalled_event['event'], unmarshalled_event['args'])
        end
      end
    end
  end
end
