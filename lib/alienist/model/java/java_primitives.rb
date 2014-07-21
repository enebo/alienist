require 'alienist/model/java/java_primitive'

module Alienist
  module Model
    module Java
      ##
      # All primitives read in a single value and are identical
      # in how they are constructed.
      def self.java_primitive(class_name, reader_method_name)
        class_eval <<-EOS
          class #{class_name} < Alienist::Model::Java::JavaPrimitive
            def initialize(value)
              super value
            end

            def self.parse(reader)
              reader.#{reader_method_name}
            end
          end
        EOS
      end

      java_primitive(:JavaBoolean, :read_boolean)
      java_primitive(:JavaByte, :read_byte)
      java_primitive(:JavaChar, :read_char)
      java_primitive(:JavaDouble, :read_double)
      java_primitive(:JavaFloat, :read_float)
      java_primitive(:JavaInt, :read_int)
      java_primitive(:JavaLong, :read_long)
      java_primitive(:JavaShort, :read_short)
    end
  end
end
