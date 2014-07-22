module Alienist
  module Model
    module Java
      class JavaObject
        attr_reader :id, :name, :signature, :cls
        attr_accessor :field_values

        def initialize(id, serial, class_id, field_io_offset)
          @id, @serial, @class_id = id, serial, class_id
          @field_io_offset = field_io_offset
        end

        ##
        # Populate remaining data associated with this in-memory representation
        def resolve(parser, snapshot)
          @cls = snapshot.id2class(@class_id)
          @field_values = parser.read_instance_fields @cls, @field_io_offset
          @cls.add_instance self
        end

        ##
        # Note: This is not a hash because subclass can shadow field names.
        def fields
          @cls.heap_order_field_names.zip(@field_values)
        end

        def inspect
          "#{@id}:#{@cls ? @cls.name : "NOTHING"}"
        end
        alias :to_s :inspect
      end
    end
  end
end
