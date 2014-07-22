module Alienist
  module Model
    module Java
      class JavaPrimitive
        attr_reader :value
        
        def initialize(value, type_label)
          @value, @type_label = value, type_label
        end

        def inspect
          "#{@type_label}: #{@value.to_s}"
        end
      end
    end
  end
end
