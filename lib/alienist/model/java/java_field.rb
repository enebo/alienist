module Alienist
  module Model
    module Java
      class JavaField
        attr_reader :id, :name, :signature
        attr_accessor :value_id

        def initialize(id, name, signature)
          @id, @name, @signature = id, name, signature
        end

        def inspect
          "#{name}:#{signature}#{value_id}"
        end
        alias :to_s :inspect
      end
    end
  end
end
