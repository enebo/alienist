module Alienist
  module Model
    module Java
      class JavaValueArray
        attr_reader :field_values
        
        def initialize(id, serial, length, signature, field_io_offset)
          @id, @serial, @length, @signature = id, serial, length, signature
          @field_io_offset = field_io_offset
        end

        ##
        # Populate remaining data associated with this in-memory representation
        def resolve(snapshot)
          @cls = snapshot.name2class('[' + @signature)
          @cls.add_instance self
        end

        def resolve_fields(parser, snapshot)
          @field_values = parser.read_array_fields @cls, @field_io_offset, @length, @signature
          @field_values = @field_values.force_encoding "UTF-16BE" if @field_values && @signature == 'C'
        end

        # primitive arrays cannot be a ruby instance so noop
        def resolve_ruby_instance(shapshot)
        end

        def inspect
          @field_values.inspect
        end
      end
    end
  end
end
