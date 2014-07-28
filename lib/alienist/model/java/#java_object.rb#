module Alienist
  module Model
    module Java
      class JavaObject
        attr_reader :id, :name, :signature, :cls
        attr_accessor :field_values, :display_value

        def initialize(id, serial, class_id, field_io_offset)
          @id, @serial, @class_id = id, serial, class_id
          @field_io_offset = field_io_offset
        end

        ##
        # Populate remaining data associated with this in-memory representation
        def resolve(snapshot)
          @cls = snapshot.id2class(@class_id)
          @cls.add_instance self
        end

        def resolve_fields(parser, snapshot)
          @field_values = parser.read_instance_fields @cls, @field_io_offset

          if snapshot.pretty_display? self
            @display_value = snapshot.create_pretty_display self
          end
        end

        def field(name)
          index = 0
          cls.instance_fields do |field|
            return field_values[index] if name == field.name
            index += 1
          end
          nil
        end

        ##
        # Note: This is not a hash because subclass can shadow field names.
        def fields
          @cls.heap_order_field_names.zip(@field_values)
        end

        def inspect
          @display_value || "#{@id}:#{@cls ? @cls.name : "NOTHING"}"
        end
        alias :to_s :inspect
      end
    end
  end
end
