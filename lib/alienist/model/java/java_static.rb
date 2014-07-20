module Alienist
  module Model
    module Java
      class JavaStatic
        attr_reader :field, :value

        def initialize(field, value)
          @field, @value = field, value
        end
      end
    end
  end
end
