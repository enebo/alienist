module Alienist
  module Model
    module Java
      class JavaStatic
        attr_reader :field, :value

        def initialize(field, value)
          @field, @value = field, value
        end

        def inspect
          "#{field.name}:#{field.signature}"
        end
        alias :to_s :inspect
      end
    end
  end
end
