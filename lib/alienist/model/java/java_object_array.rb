module Alienist
  module Model
    module Java
      class JavaObjectArray
        def initialize(id, serial, length, class_id, field_io_offset)
          @id, @serial, @length, @class_id = id, serial, length, class_id
          @field_io_offset = field_io_offset
        end

        ##
        # Populate remaining data associated with this in-memory representation
        def resolve(parser, snapshot)
          @cls = snapshot.id2class(@class_id)

          # FIXME: read in raw value
          # @field_values = parser.read_instance_fields @cls, @field_io_offset
          @cls.add_instance self
        end
      end
    end
  end
end
