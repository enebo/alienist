module Alienist
  module Model
    module Java
      class JavaObjectArray
        attr_reader :field_values
        
        def initialize(id, serial, length, class_id, field_io_offset)
          @id, @serial, @length, @class_id = id, serial, length, class_id
          @field_io_offset = field_io_offset
        end

        ##
        # Populate remaining data associated with this in-memory representation
        def resolve(snapshot)
          @cls = snapshot.id2class(@class_id)

          @cls.add_instance self
        end

        def resolve_fields(parser, snapshot)
          @field_values = parser.read_object_array @cls, @field_io_offset, @length
        end

        # Object[] can contain Ruby instances but it cannot be one itself
        def resolve_ruby_instance(shapshot)
        end

        def inspect
          "Obj[clsid=#{@class_id}, len=#{@length}]"
        end
        alias :to_s :inspect
      end
    end
  end
end
