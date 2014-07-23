module Alienist
  module Model
    module Java
      class JavaValueArray
        def initialize(id, serial, length, signature, element_size, field_io_offset)
          @id, @serial, @length = id, serial, length
          @signature, @element_size = signature, element_size
          
          @field_io_offset = field_io_offset
        end

        ##
        # Populate remaining data associated with this in-memory representation
        def resolve(snapshot)
          @cls = snapshot.name2class('[' + @signature)

          unless @cls
            puts "Cannot find class_name #{ARRAY_TYPES[@signature]} for sig #{@signature}"
            return
          end
          
          # FIXME: read in raw value
          # @field_values = parser.read_instance_fields @cls, @field_io_offset
          @cls.add_instance self
        end

        def resolve_fields(parser)
        end
      end
    end
  end
end
