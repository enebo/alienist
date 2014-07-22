require 'alienist/model/java/java_primitive'

module Alienist
  module Model
    module Java
      ##
      # All primitives read in a single value and are identical
      # in how they are constructed.
      def self.java_primitive(class_name, reader_method_name, type_label)
        class_eval <<-EOS
          class #{class_name} < Alienist::Model::Java::JavaPrimitive
            def self.create(reader)
              new parse(reader), '#{type_label}'
            end

            def self.parse(reader)
              reader.#{reader_method_name}
            end
          end
        EOS
      end

      java_primitive(:JavaBoolean, :read_boolean, 'boolean')
      java_primitive(:JavaByte, :read_byte, 'byte')
      java_primitive(:JavaChar, :read_char, 'char')
      java_primitive(:JavaDouble, :read_double, 'double')
      java_primitive(:JavaFloat, :read_float, 'float')
      java_primitive(:JavaInt, :read_int, 'int')
      java_primitive(:JavaLong, :read_long, 'long')
      java_primitive(:JavaObjectRef, :read_id, 'ref') # Close enough to prim.
      java_primitive(:JavaShort, :read_short, 'short')
    end
  end
end
