require 'alienist/model/java/java_class'
require 'alienist/model/java/java_primitives'
require 'alienist/model/java/java_object'
require 'alienist/model/java/java_object_array'
require 'alienist/model/java/java_value_array'
require 'alienist/model/java/java_field'
require 'alienist/model/java/java_static'
require 'alienist/snapshot/base_snapshot'

module Alienist
  module Snapshot
    class MemorySnapshot < Alienist::Snapshot::BaseSnapshot
      include Alienist::Model::Java
      
      attr_reader :java_lang_class, :java_lang_string
      attr_reader :instances
      
      def initialize
        super()

        @class_from_name = {}  # name -> java_class
        @class_from_id = {}    # id   -> java_class
        @instances = {}        # id   -> java_object
      end

      def pretty_display?(obj)
        false
      end


      def create_pretty_display(obj)
      end


      def add_class(id, name, super_id, classloader_id, signers_id,
                    protection_domain_id, instance_size)
        cls = JavaClass.new self, id, name, super_id, classloader_id,
                            signers_id, protection_domain_id, instance_size

        case name
        when 'java.lang.String'
          @java_lang_string = cls
        when 'java.lang.Class'
          @java_lang_class = cls
        end
        
        @class_from_name[name] = cls
        @class_from_id[id] = cls

        cls
      end

      def add_field(cls, name_id, signature)
        name = name name_id
        cls.fields << JavaField.new(name_id, name, signature)
      end

      def add_instance(id, serial, class_id, field_io_offset)
        object = JavaObject.new id, serial, class_id, field_io_offset
        @instances[id] = object
        
        object
      end

      def add_object_array(id, serial, length, class_id, field_io_offset)
        object = JavaObjectArray.new id, serial, length, class_id, field_io_offset
        @instances[id] = object
      end

      def add_value_array(id, serial, length, signature, field_io_offset)
        array = JavaValueArray.new id, serial, length, signature, field_io_offset
        @instances[id] = array
      end

      def add_static_field(cls, name_id, signature, value)
        name = name name_id
        field = JavaField.new name_id, name, signature
        cls.static_fields[name] = JavaStatic.new field, value
      end

      def name2class(name)
        @class_from_name[name]
      end

      def id2class(id)
        @class_from_id[id]
      end

      def classes
        @class_from_id.values
      end

      def resolve(parser)
        # King of kings of all Java classes.  Special attr for easy access.
        @java_lang_class = name2class 'java.lang.Class'
        @class_from_id.each { |name, cls| cls.resolve }
        @instances.values.each { |instance| instance.resolve self }
        @instances.values.each { |instance| instance.resolve_fields parser, self }
      end

      def resolve_object_ref(id)
        return JavaNull if id == 0

        value = @instances[id] || @class_from_id[id]
        value
      end

    end
  end
end
