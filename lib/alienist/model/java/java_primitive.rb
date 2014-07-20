module Alienist
  module Model
    module Java
      class JavaPrimitive
        attr_reader :value
        
        def initialize(value)
          @value = value
        end
      end
    end
  end
end
