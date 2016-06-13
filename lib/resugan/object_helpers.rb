module Resugan
  module ObjectHelpers
    def self.included base
      base.extend ClassMethods
    end

    module ClassMethods
      def attach_hook(method, options = {})
        alias_method "_resugan_orig_#{method}".to_sym, method.to_sym

        define_method(method.to_sym) do |*args|
          resugan options[:namespace] do
            send("_resugan_orig_#{method}".to_sym, *args)
          end
        end
      end
    end
  end
end
