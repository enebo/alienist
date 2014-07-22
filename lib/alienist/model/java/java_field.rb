module Alienist
  module Model
    module Java
      class JavaField
        attr_reader :id, :name, :signature

        def initialize(id, name, signature)
          @id, @name, @signature = id, name, signature
        end

        def inspect
          "#{name}:#{signature}"
        end
        alias :to_s :inspect
      end
    end
  end
end
