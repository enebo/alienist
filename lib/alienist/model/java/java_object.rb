require 'alienist/model/ruby_value_converters'

module Alienist
  module Model
    module Java
      class JavaObject
        include Alienist::Model::RubyValueConverters

        attr_reader :id, :name, :signature, :cls, :size
        attr_accessor :field_values

        # Ruby Classes are instances of a Java Object
        attr_reader :ruby_instances, :ruby_metaclass, :ruby_data_converter

        def initialize(id, serial, class_id, field_io_offset, size)
          @id, @serial, @class_id, @size = id, serial, class_id, size
          @field_io_offset = field_io_offset
          @ruby_metaclass, @ruby_class, @ruby_data_converter = nil, false, nil
          @ruby_instances = []
        end

        ##
        # Get field value for the specific named field.
        #
        # FIXME: This will find first field by name from base class up. So this method is inadequate for
        # shadowed variables.
        def field(name)
          index = 0
          cls.instance_fields do |field|
            return field_values[index] if name == field.name
            index += 1
          end
          nil
        end

        def field_path(first, *rest)
          instance = field first
          rest.inject(instance) do |instance, field_name|
            return nil unless instance.respond_to? :field
            instance.field field_name
          end
        end

        ##
        # A name/value list of all fields for this Java Object.
        #
        # Note: This is not a hash because subclass can shadow field names.
        def fields
          @cls.heap_order_field_names.zip(@field_values)
        end

        def inspect
          "#{@id}:#{@cls ? @cls.name : "NOTHING"}"
        end
        alias :to_s :inspect

        ##
        # Populate remaining data associated with this in-memory representation
        def resolve(snapshot)
          @cls = snapshot.id2class(@class_id)
          @cls.add_instance self
        end

        def resolve_fields(parser, snapshot)
          @field_values = parser.read_instance_fields @cls, @field_io_offset
        end

        def resolve_ruby_class(snapshot)
          name = ruby_name
          snapshot.register_ruby_class self, name
          @ruby_data_converter = converter_for name
          @ruby_class = true
        end

        ##
        # If this is a Ruby instance resolve what it is and what it has.
        def resolve_ruby_instance(snapshot)
          cls = field('metaClass') || return
          cls = snapshot.ruby_classes['BasicObject'] if !cls.respond_to? 'fields'
          cls.ruby_instances << self
          @ruby_metaclass = cls
        end

        def ruby_data_value
          @ruby_metaclass.ruby_data_converter.call self
        end

        ##
        # Returns a list of [:name => :java_object_id, ...].
        def ruby_instance_variables
          # BasicObject this is wrong.  They can have fields...
          return [] unless @ruby_metaclass.respond_to? :fields

          vn = @ruby_metaclass.field_path 'variableTableManager', 'variableNames'
          names = vn.field_values.inject([]) do |list, str|
            list << str.field('value').field_values
          end

          vt = field 'varTable'
          vt == Alienist::Model::Java::JavaNull ? [] : names.zip(vt.field_values.map(&:id))
        end

        # FIXME: We can try for cachedName but I am using sure thing even if slower
        def ruby_name
          base_name = base_name_of self

          return "ANON:IMPL_ME" unless base_name

          # Likely incorrect if Foo::Object where this Object is not ::Object
          return base_name if base_name == "Object" || base_name == "BasicObject"

          names = [base_name]

          cls = self
          loop do
            cls = cls.field 'parent'
            base_name = base_name_of cls

            break if !base_name || base_name == 'Object'
            names << base_name
          end

          names.reverse.join '::'
        end


        def base_name_of(cls)
          return nil if !cls || cls.kind_of?(JavaNullClass)

          value = cls.field_path 'baseName', 'value'
          value && value.respond_to?(:field_values) ? value.field_values.encode("UTF-8") : nil
        end

        ##
        # Does this Java Object represent a Ruby class
        def ruby_class?
          @ruby_class
        end

        def ruby_instance?
          @ruby_metaclass
        end
      end
    end
  end
end
