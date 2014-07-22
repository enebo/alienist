module Alienist
  module Model
    module Java
      class JavaObject
        attr_reader :id, :name, :signature
        attr_accessor :field_values

        def initialize(id, serial, cls)
          @id, @serial, @cls = id, serial, cls
        end

        def inspect
          "#{@id}:#{@cls ? @cls.name : "NOTHING"}"
        end
        alias :to_s :inspect
      end
    end
  end
end
